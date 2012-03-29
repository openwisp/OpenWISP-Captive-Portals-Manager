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

#noinspection RubyResolve
require 'digest/md5'

class OnlineUser < ActiveRecord::Base

  belongs_to :captive_portal

  # TODO: validate password format (?? How ?? We have to be consistent with others class password attribute)
  validates_presence_of :password

  validates_inclusion_of :radius, :in => [ true, false ]

  validates_numericality_of :session_timeout, :allow_nil => true
  validates_numericality_of :idle_timeout, :allow_nil => true

  validates_numericality_of :max_upload_bandwidth, :greater_than => 0, :allow_nil => true
  validates_numericality_of :max_download_bandwidth, :greater_than => 0, :allow_nil => true

  validates_numericality_of :uploaded_octets, :greater_than_or_equal_to => 0
  validates_numericality_of :downloaded_octets, :greater_than_or_equal_to => 0
  validates_numericality_of :uploaded_packets, :greater_than_or_equal_to => 0
  validates_numericality_of :downloaded_packets, :greater_than_or_equal_to => 0

  validates_format_of :mac_address, :with => /\A([0-9a-f]{2}:){5}[0-9a-f]{2}\Z/
  validates_format_of :ip_address,
                      :with => /\A((([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|(25[0-5]))\.){3}([0-9])|([1-9][0-9])|(1[0-9][0-9])|(2[0-4][0-9])|(25[0-5])\Z/

  validates_uniqueness_of :ip_address
  validates_uniqueness_of :mac_address
  validates_uniqueness_of :cp_session_token

  before_create {
      # Generates the cp_session_token. Where applicable this id it's used also as a unique RADIUS session id.
    self.cp_session_token = (Digest::MD5.hexdigest(Time.new.to_s + self.username + self.password + self.ip_address +
                                                       self.mac_address))[0..16]
  }

  after_create {
      # Let the user pass through the firewall...
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.add_user(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :address => self.ip_address,
            :mac => self.mac_address,
            :max_upload_bandwidth => self.max_upload_bandwidth,
            :max_download_bandwidth => self.max_download_bandwidth
        }
    )
  }

  before_destroy {
    # This could be invoked from a worker, so we must use async_ here to
    # avoid deadlocks
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_remove_user(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :address => self.ip_address,
            :mac => self.mac_address,
            :max_upload_bandwidth => self.max_upload_bandwidth,
            :max_download_bandwidth => self.max_download_bandwidth
        }
    )
  }

  def initialize(options = {})
    options[:uploaded_octets] ||= 0
    options[:downloaded_octets] ||= 0
    options[:uploaded_packets] ||= 0
    options[:downloaded_packets] ||= 0
    super(options)
    self.last_activity = Time.now
  end

  def update_activity!(uploaded_octets, downloaded_octets, uploaded_packets, downloaded_packets)
    unless uploaded_octets == self.uploaded_octets and downloaded_octets == self.downloaded_octets
      self.uploaded_octets = uploaded_octets
      self.downloaded_octets = downloaded_octets
      self.uploaded_packets = uploaded_packets
      self.downloaded_packets = downloaded_packets
      self.last_activity = Time.new
      unless self.save
        logger.error("Failed to update activity of user '#{self.username}'")
        logger.error("...forcing the update of '#{self.username}' acrivity")
        self.save false
      end
    else
      false
    end
  end

  def RADIUS_user?
    self.radius
  end

  def local_user?
    ! self.radius
  end

  def session_time_interval
    (Time.now - self.created_at).to_i
  end

  def last_activity_interval
    (Time.now - self.last_activity).to_i
  end

  def inactive?
    return false if self.idle_timeout.nil?
    self.last_activity_interval > self.idle_timeout
  end

  def expired?
    return false if self.session_timeout.nil?
    self.session_time_interval > self.session_timeout
  end

  def refresh!
    uploaded_octets, downloaded_octets = octets_counters
    uploaded_packets, downloaded_packets = packets_counters
    update_activity!(uploaded_octets, downloaded_octets, uploaded_packets, downloaded_packets)
  end

  protected
  def octets_counters
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.get_user_bytes_counters(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :address => self.ip_address,
            :mac => self.mac_address
        }
    )
  end

  def packets_counters
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.get_user_packets_counters(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :address => self.ip_address,
            :mac => self.mac_address
        }
    )
  end

end
