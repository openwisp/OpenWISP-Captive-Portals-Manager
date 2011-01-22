class LocalUser < ActiveRecord::Base

  belongs_to :captive_portal

  validates_format_of :username, :with => /\A[0-9a-zA-Z:_\.\s\+\-]+\Z/
  validates_length_of :username, :within => 6..32

  validates_format_of :password, :with => /\A[0-9a-zA-Z:_\.\s\+\-]+\Z/
  validates_length_of :password, :within => 8..32

  validates_numericality_of :max_upload_bandwidth, :greater_than => 0,
                            :allow_nil => true, :allow_blank => true
  validates_numericality_of :max_download_bandwidth, :greater_than => 0,
                            :allow_nil => true, :allow_blank => true

  validates_presence_of :disabled_message, :if => "disabled?"

  attr_readonly :username

  def self.authenticate(username, password)
    user = where("username = ? AND password = ?", username, password).first
    reply = Hash.new
    if user.nil?
      reply[:authenticated] = nil
      reply[:message] = I18n.t(:invalid_credentials)
    elsif user.disabled?
      reply[:authenticated] = false
      reply[:message] = user.disabled_message
    elsif !user.allow_concurrent_login? and !OnlineUser.find_by_username(user.username).nil?
      reply[:authenticated] = false
      reply[:message] = I18n.t(:concurrent_login_not_allowed)
    else
      reply[:authenticated] = true
      reply[:message] = ""
    end

    if reply[:authenticated]
      reply[:max_upload_bandwidth] = user.max_upload_bandwidth
      reply[:max_download_bandwidth] = user.max_download_bandwidth
    end

    return reply
  end

end
