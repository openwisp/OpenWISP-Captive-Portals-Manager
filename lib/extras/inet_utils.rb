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

require 'socket'
require 'ipaddr'

module InetUtils

  def get_source_address(dest_address)
    orig_reverse_lookup_setting = Socket.do_not_reverse_lookup
    Socket.do_not_reverse_lookup = true

    UDPSocket.open(IPAddr.new(dest_address).ipv6? ? Socket::AF_INET6 : Socket::AF_INET) do |sock|
      sock.connect dest_address, 1
      sock.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig_reverse_lookup_setting
  end

  module_function :get_source_address
  
end
