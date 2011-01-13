class CaptivePortal < ActiveRecord::Base

  has_many :local_users
  has_many :online_users
  has_many :allowed_traffics
  has_one :radius_auth_server
  accepts_nested_attributes_for :radius_auth_server, :allow_destroy => true,
                                :reject_if => proc { |attributes| attributes[:host].blank? }
  has_one :radius_acct_server
  accepts_nested_attributes_for :radius_acct_server, :allow_destroy => true,
                                :reject_if => proc { |attributes| attributes[:host].blank? }

  # Default url to redirect clients to if session[:original_url] is not present
  DEFAULT_URL="http://rubyonrails.org/"

  validates_format_of :name, :with => /\A[a-zA-Z][a-zA-Z0-9\.\-]*\Z/
  validates_uniqueness_of :name
  validates_uniqueness_of :cp_interface
  validates_format_of :cp_interface, :with => /\A[a-zA-Z][a-zA-Z0-9\.\-]*\Z/
  validates_format_of :wan_interface, :with => /\A[a-zA-Z][a-zA-Z0-9\.\-]*\Z/

  validates_format_of :redirection_url, :with => /\A[a-zA-Z0-9:<%%>_=&\?\.\-\/\.]*\Z/
  validates_format_of :error_url, :with => /\A[a-zA-Z0-9:<%%>_=&\?\.\-\/\.]*\Z/

  validates_numericality_of :local_http_port, :less_than_or_equal_to => 65535, :greater_than_or_equal_to => 0
  validates_numericality_of :local_https_port, :less_than_or_equal_to => 65535, :greater_than_or_equal_to => 0

  validates_numericality_of :default_download_bandwidth, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :default_upload_bandwidth, :greater_than_or_equal_to => 0, :allow_nil => true

  validates_numericality_of :default_session_timeout, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :default_idle_timeout, :greater_than_or_equal_to => 0, :allow_nil => true

  validates_numericality_of :total_download_bandwidth, :greater_than_or_equal_to => 0, :allow_nil => true
  validates_numericality_of :total_upload_bandwidth, :greater_than_or_equal_to => 0, :allow_nil => true

  attr_readonly :cp_interface, :wan_interface

  after_create {
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_add_cp(
        :args => {
            :cp_interface => cp_interface,
            :wan_interface => wan_interface,
            :local_http_port => local_http_port,
            :local_https_port => local_https_port
        }
    )
  }

  before_destroy {
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_remove_cp(
        :args => {
            :cp_interface => cp_interface
        }
    )
  }

  after_save {
    unless self.new_record?
      worker = MiddleMan.worker(:captive_portal_worker)
      # cp_interface is a readonly attribute so it wont be changed
      worker.remove_cp(
          :args => {
              :cp_interface => cp_interface
          }
      )
      worker.add_cp(
          :args => {
              :cp_interface => cp_interface,
              :wan_interface => wan_interface,
              :local_http_port => local_http_port,
              :local_https_port => local_https_port
          }
      )
    end
  }

  def compile_redirection_url(options = {})
    url = redirection_url
    options[:mac_address] ||= ""
    options[:ip_address] ||= ""
    options[:original_url] ||= ""

    url.gsub!(/<%\s*MAC_ADDRESS\s*%>/, URI.escape(options[:mac_address], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))
    url.gsub!(/<%\s*IP_ADDRESS\s*%>/, URI.escape(options[:ip_address], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))
    url.gsub!(/<%\s*ORIGINAL_URL\s*%>/, URI.escape(options[:original_url], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))

    url
  end

  def compile_error_url(options = {})
    url = error_url

    options[:mac_address] ||= ""
    options[:ip_address] ||= ""
    options[:original_url] ||= ""
    if options[:message].nil? or options[:message].blank?
      options[:message] = I18n.t(:no_message)
    end

    url.gsub!(/<%\s*MAC_ADDRESS\s*%>/, URI.escape(options[:mac_address], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))
    url.gsub!(/<%\s*IP_ADDRESS\s*%>/, URI.escape(options[:ip_address], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))
    url.gsub!(/<%\s*ORIGINAL_URL\s*%>/, URI.escape(options[:original_url], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))
    url.gsub!(/<%\s*MESSAGE\s*%>/, URI.escape(options[:message], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")))

    url
  end

  def authenticate_user(username, password, client_ip, client_mac)
    radius = false
    reply = LocalUser.authenticate(username, password)
    if reply[:authenticated].nil? and !radius_auth_server.nil?
      radius = true
      reply = radius_auth_server.authenticate(
          {
              :username => username,
              :password => password,
              :ip => client_ip,
              :mac => client_mac
          }
      )
      if reply.nil?
        reply[:authenticated] = false
        reply[:message] = "RADIUS authentication internal error"
      end
    end

    if reply[:authenticated]
      # Add user to the online users
      user = online_users.build(
          :username => username,
          :password => password,
          :radius => radius,
          :ip_address => client_ip,
          :mac_address => client_mac,
          :idle_timeout => reply[:idle_timeout],
          :session_timeout => reply[:session_timeout],
          :max_upload_bandwidth => reply[:max_upload_bandwidth] || self.default_upload_bandwidth,
          :max_download_bandwidth => reply[:max_download_bandwidth] || self.default_download_bandwidth
      )
      begin
        user.save!
      rescue Exception => e
        return [ nil , "Cannot save user, internal error (#{e})" ]
      end
      
      unless self.radius_acct_server.nil?
        radius_acct_server.accounting_start(
            {
                :username => user.username,
                :sessionid => user.cp_session_token,
                :ip => user.ip_address,
                :mac => user.mac_address,
                :radius => user.RADIUS_user?
            }
        )
      end
      [ user.cp_session_token, reply[:message] ]
    else
      [ nil, reply[:message]]
    end
  end

  def deauthenticate_user(user, reason)
    unless user.nil?
      ##  Commented out to permit the use of a RADIUS accounting server even
      ##  if we have no RADIUS authentication server...
      if !radius_acct_server.nil?

        radius_acct_server.accounting_stop(
            {
                :username => user.username,
                :sessionid => user.cp_session_token,
                :ip => user.ip_address,
                :mac => user.mac_address,
                :radius => user.RADIUS_user?,
                :session_time => user.session_time_interval,
                :session_uploaded_octets => user.uploaded_octets,
                :session_uploaded_packets => user.uploaded_packets,
                :session_downloaded_octets => user.downloaded_octets,
                :session_downloaded_packets => user.downloaded_packets,
                :termination_cause => reason
            }
        )
      end

      user.destroy
    end
  end

  def deauthenticate_online_users(reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Forced_logout])
    self.online_users.each do |user|
      deauthenticate_user(user, reason)
    end
  end

  def online_users_upkeep
    self.online_users.each do |user|

      to_be_disconnected = false
      reason = nil

      if user.inactive?
        to_be_disconnected = true
        reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Idle_timeout]
      elsif user.expired?
        to_be_disconnected = true
        reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Session_timeout]
      elsif user.RADIUS_user?
        reply = self.radius_auth_server.authenticate(
            {
                :username => user.username,
                :password => user.password,
                :ip => user.ip_address,
                :mac => user.mac_address
            }
        )
        to_be_disconnected = !reply[:authenticated]
        reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:User_Error] if to_be_disconnected
      end

      if to_be_disconnected
        self.deauthenticate_user(user, reason)
        next
      else
        unless self.radius_acct_server.nil?
          self.radius_acct_server.accounting_update(
              {
                  :username => user.username,
                  :sessionid => user.cp_session_token,
                  :session_time => user.session_time_interval,
                  :session_uploaded_octets => user.uploaded_octets,
                  :session_uploaded_packets => user.uploaded_packets,
                  :session_downloaded_octets => user.downloaded_octets,
                  :session_downloaded_packets => user.downloaded_packets,
                  :ip => user.ip_address,
                  :mac => user.mac_address,
                  :radius => user.RADIUS_user?
              }
          )
        end
      end
    end
  end

end
