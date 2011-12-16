# This file is part of the OpenWISP Captive Portal Manager
#
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

require 'radiustar'

class RadiusServer < ActiveRecord::Base

  DICTIONARY_DIR = Rails.root.join("lib", "RADIUS", "dictionaries")

  @@dictionary = Radiustar::Dictionary.new(DICTIONARY_DIR)

  DEFAULT_REQUEST_TIMEOUT = 2 # Seconds
  DEFAULT_REQUEST_RETRIES = 3

  validates_numericality_of :port, :greater_than => 0, :less_than_or_equal_to => 65535
  validates_format_of :host, :with => /\A[0-9\.]+\Z/
  # From FreeRadius Proxy.conf:
  ##  The secret can be any string, up to 8k characters in length.
  validates_length_of :shared_secret, :within => 8..8192
  validates_format_of :host, :with => /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/

  def initialize(options = {})
    options[:port] || raise("BUG: RADIUS port must be specified")
    super(options)
  end

  #noinspection RubyResolve
  def self.dictionary
    @@dictionary
  end
end
