# This file is part of the OpenWISP Captive Portal Manager
#
# Copyright (C) 2011 CASPUR (wifi@caspur.it)
#
# This software is licensed under a Creative  Commons Attribution-NonCommercial
# 3.0 Unported License.
#   http://creativecommons.org/licenses/by-nc/3.0/
#
# Please refer to the  README.license  or contact the copyright holder (CASPUR)
# for licensing details.
#

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
