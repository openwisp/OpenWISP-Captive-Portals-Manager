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
