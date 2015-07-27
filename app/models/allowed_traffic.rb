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

class AllowedTraffic < ActiveRecord::Base

  belongs_to :captive_portal

  validates_inclusion_of :protocol, :in => %w(tcp udp), :allow_nil => true, :allow_blank => true
  validates_format_of :source_mac_address, :with => /\A([0-9a-f]{2}:){5}[0-9a-f]{2}\Z/i, :allow_nil => true, :allow_blank => true
  validates_format_of :source_host, :with => /\A[a-zA-Z0-9:\-\.\/]+\Z/, :allow_nil => true, :allow_blank => true
  validates_numericality_of :source_port, :greater_than => 0, :less_than_or_equal_to => 65535,
                            :allow_nil => true, :allow_blank => true

  validates_format_of :destination_host, :with => /\A[a-zA-Z0-9:\-\.\/]+\Z/, :allow_nil => true, :allow_blank => true
  validates_numericality_of :destination_port, :greater_than => 0, :less_than_or_equal_to => 65535,
                            :allow_nil => true, :allow_blank => true

  attr_accessible :protocol, :source_mac_address, :source_host, :source_port, :destination_host, :destination_port, :note

  after_create {
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_add_allowed_traffic(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :source_mac => self.source_mac_address,
            :source_host => self.source_host,
            :destination_host => self.destination_host,
            :protocol => self.protocol,
            :source_port => self.source_port,
            :destination_port => self.destination_port
        }
    )
  }

  before_update {
    old_allowed_traffic = AllowedTraffic.find( self.id )
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_remove_allowed_traffic(
        :args => {
            :cp_interface => old_allowed_traffic.captive_portal.cp_interface,
            :source_mac => old_allowed_traffic.source_mac_address,
            :source_host => old_allowed_traffic.source_host,
            :destination_host => old_allowed_traffic.destination_host,
            :protocol => old_allowed_traffic.protocol,
            :source_port => old_allowed_traffic.source_port,
            :destination_port => old_allowed_traffic.destination_port
        }
    )
    worker.async_add_allowed_traffic(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :source_mac => self.source_mac_address,
            :source_host => self.source_host,
            :destination_host => self.destination_host,
            :protocol => self.protocol,
            :source_port => self.source_port,
            :destination_port => self.destination_port
        }
    )
  }

  before_destroy {
      # This could be invoked from a worker, so we must use async_ here to avoid deadlocks
    worker = MiddleMan.worker(:captive_portal_worker)
    worker.async_remove_allowed_traffic(
        :args => {
            :cp_interface => self.captive_portal.cp_interface,
            :source_mac => self.source_mac_address,
            :source_host => self.source_host,
            :destination_host => self.destination_host,
            :protocol => self.protocol,
            :source_port => self.source_port,
            :destination_port => self.destination_port
        }
    )
  }

end
