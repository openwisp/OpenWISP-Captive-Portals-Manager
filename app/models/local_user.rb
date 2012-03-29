# This file is part of the OpenWISP Captive Portal Manager
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
