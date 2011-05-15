class CaptivePortal < ActiveRecord::Base

  has_many :local_users, :dependent => :destroy
  has_many :online_users, :dependent => :destroy
  has_many :allowed_traffics, :dependent => :destroy
  has_one :radius_auth_server, :dependent => :destroy
  accepts_nested_attributes_for :radius_auth_server, :allow_destroy => true,
                                :reject_if => proc { |attributes| attributes[:host].blank? }
  has_one :radius_acct_server, :dependent => :destroy
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

  validates_numericality_of :default_session_timeout, :greater_than_or_equal_to => 0, :allow_blank => true
  validates_numericality_of :default_idle_timeout, :greater_than_or_equal_to => 0, :allow_blank => true

  validates_numericality_of :total_download_bandwidth, :greater_than => 0, :allow_blank => true
  validates_numericality_of :total_upload_bandwidth, :greater_than => 0, :allow_blank => true
  
  validates_numericality_of :default_download_bandwidth, :greater_than => 0, :allow_blank => true
  validates_numericality_of :default_upload_bandwidth, :greater_than => 0, :allow_blank => true

  validates_presence_of :default_download_bandwidth, :unless => Proc.new { self.total_download_bandwidth.blank? }
  validates_presence_of :default_upload_bandwidth, :unless => Proc.new { self.total_upload_bandwidth.blank? }

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
      worker.bootstrap_cp(:args => { :cp => self.id })
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
    # TO DO: Radius request offload ... (sync for auth, async for acct)
    radius = false
    reply = Hash.new

    # First look in local user
    local_user = local_users.where(:username => username).first
    if !local_user.nil?
      if local_user.check_password(password)
        # Password is valid, check if the user can log in

        ## Is the user disabled?
        if local_user.disabled?
          reply[:authenticated] = false
          reply[:message] = local_user.disabled_message
        end

        ## Is the user already logged in and multiple login are not allowed for him?
        if reply[:authenticated].nil? and !local_user.allow_concurrent_login? and
            online_users.count(:conditions => {:username => username}) > 0
          reply[:authenticated] = false
          reply[:message] = I18n.t(:concurrent_login_not_allowed)
        end

        ## Is a good guy, grant him/her access
        if reply[:authenticated].nil?
          reply[:authenticated] = true
          reply[:message] = ""
          reply[:max_upload_bandwidth] = local_user.max_upload_bandwidth
          reply[:max_download_bandwidth] = local_user.max_download_bandwidth
          # TO DO: add timeouts to LocalUser model
          reply[:idle_timeout] = self.default_idle_timeout
          reply[:session_timeout] = self.default_session_timeout
        end

      else
        # Invalid password
        reply[:authenticated] = false
        reply[:message] = I18n.t(:invalid_credentials)
      end
    end

    # Then, if the user is still not auth'ed, ask a RADIUS server (if defined)
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

    if !reply[:authenticated].nil? and reply[:authenticated]
      # Access granted, add user to the online users
      online_user = online_users.build(
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
        online_user.save!
      rescue Exception => e
        [ nil , "Cannot save user, internal error (#{e})" ]
      end

      unless self.radius_acct_server.nil?
        worker = MiddleMan.worker(:captive_portal_worker)
        worker.async_accounting_start(
            :args => {
                :acct_server_id => self.radius_acct_server.id,
                :username => online_user.username,
                :sessionid => online_user.cp_session_token,
                :ip => online_user.ip_address,
                :mac => online_user.mac_address,
                :radius => online_user.RADIUS_user?
            }
        )
      end
      [ online_user.cp_session_token, reply[:message] ]
    else
      # Login failed!
      [ nil, reply[:message] || I18n.t(:invalid_credentials) ]
    end
  end

  # The following functions are intended to be offloaded (i.e. should always be called from a worker)
  # DO NOT start a *synchronous* worker job inside the following functions!.

  def deauthenticate_user(online_user, reason)
    unless radius_acct_server.nil?
      # Use a RADIUS accounting server even if we have no RADIUS auth server
      worker = MiddleMan.worker(:captive_portal_worker)
      worker.async_accounting_stop(
          :args => {
              :acct_server_id => self.radius_acct_server.id,
              :username => online_user.username,
              :sessionid => online_user.cp_session_token,
              :ip => online_user.ip_address,
              :mac => online_user.mac_address,
              :radius => online_user.RADIUS_user?,
              :session_time => online_user.session_time_interval,
              :session_uploaded_octets => online_user.uploaded_octets,
              :session_uploaded_packets => online_user.uploaded_packets,
              :session_downloaded_octets => online_user.downloaded_octets,
              :session_downloaded_packets => online_user.downloaded_packets,
              :termination_cause => reason
          }
      )
    end
  ensure
    online_user.destroy
  end

  def deauthenticate_online_users(reason = RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Forced_logout])
    self.online_users.each do |online_user|
      deauthenticate_user(online_user, reason)
    end
  end

end
