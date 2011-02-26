class LocalUser < ActiveRecord::Base

  belongs_to :captive_portal

  validates_format_of :username, :with => /\A[0-9a-zA-Z:_\.\s\+\-]+\Z/
  validates_length_of :username, :within => 6..32
  validates_uniqueness_of :username, :scope => [ :captive_portal_id ]

  validates_format_of :password, :with => /\A[0-9a-zA-Z:_\.\s\+\-]+\Z/
  validates_length_of :password, :within => 8..32

  validates_numericality_of :max_upload_bandwidth, :greater_than => 0,
                            :allow_nil => true, :allow_blank => true
  validates_numericality_of :max_download_bandwidth, :greater_than => 0,
                            :allow_nil => true, :allow_blank => true

  validates_presence_of :disabled_message, :if => "disabled?"

  attr_readonly :username

  # Simple as can be :-D
  def check_password(password)
    self.password == password
  end

end
