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

require 'radiustar'

class RadiusServer < ActiveRecord::Base

  DICTIONARY_DIR = Rails.root.join("lib", "RADIUS", "dictionaries")

  @@dictionary = Radiustar::Dictionary.new(DICTIONARY_DIR)

  DEFAULT_REQUEST_TIMEOUT = 2 # Seconds
  DEFAULT_REQUEST_RETRIES = 3

  validates_numericality_of :port, :greater_than => 0, :less_than_or_equal_to => 65535
  validates_format_of :host, :with => /\A[a-zA-Z0-9:\-\.]+\Z/
  # From FreeRadius Proxy.conf:
  ##  The secret can be any string, up to 8k characters in length.
  validates_length_of :shared_secret, :within => 8..8192

  def initialize(options = {})
    options[:port] || raise("BUG: RADIUS port must be specified")
    super(options)
  end

  #noinspection RubyResolve
  def self.dictionary
    @@dictionary
  end

end
