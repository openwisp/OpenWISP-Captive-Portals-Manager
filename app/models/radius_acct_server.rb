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

class RadiusAcctServer < RadiusServer
  set_table_name :radius_acct_servers

  belongs_to :captive_portal

  attr_accessible :host, :port, :shared_secret

  DEFAULT_PORT = 1813

  SESSION_TERMINATE_CAUSE = {
      :Explicit_logout => 'User-Request',     # User explicit logout
      :Idle_timeout => 'Idle-Timeout',        # Idle timeout
      :Session_timeout => 'Session-Timeout',  # Session timeout
      :User_Error => 'User-Error',            # RADIUS rejected an authenticated user
      :CP_Restart => 'Admin-Reboot',          # Application restarted
      :Forced_logout => 'Port-Preempted'      # Admin kicked the user
  }

  @@acct_custom_attr = {
      'NAS-Port'        => 0,
      'NAS-Port-Type'   => 'Ethernet',
      'Service-Type'    => 'Login-User'
  }

  def initialize(options = {})
    options[:port] ||= DEFAULT_PORT
    super(options)
  end

  def accounting_start(request)
    request[:username] || raise("BUG: Missing 'username'")
    request[:sessionid] || raise("BUG: Missing 'sessionid'")
    request[:ip] || raise("BUG: Missing 'ip'")
    request[:mac] || raise("BUG: Missing 'mac'")
    request[:radius] ||= false

    nas_ip_address = InetUtils.get_source_address(host)

    begin
      req = Radiustar::Request.new("#{self.host}:#{self.port}",
                                   {
                                       :dict => @@dictionary,
                                       :reply_timeout =>  DEFAULT_REQUEST_TIMEOUT,
                                       :retries_number => DEFAULT_REQUEST_RETRIES
                                   }
      )
      reply = req.accounting_start(request[:username],
                                   self.shared_secret,
                                   request[:sessionid],
                                   @@acct_custom_attr.merge(
                                       {
                                           'NAS-IP-Address' => nas_ip_address,
                                           'NAS-Identifier' => captive_portal.name,
                                           'Framed-IP-Address' => request[:ip],
                                           'Calling-Station-Id' => request[:mac],
                                           'Called-Station-Id' => captive_portal.cp_interface,
                                           'Acct-Status-Type' => 'Start',
                                           'Acct-Authentic' => request[:radius] ? 'RADIUS' : 'Local'
                                       }
                                   )
      )
    rescue Exception => e
      Rails.logger.error("Failed to send RADIUS accounting stop request to #{self.host}:#{self.port} for user #{request[:username]}, sessionid #{request[:sessionid]} (#{e})")
      reply = false
    end
    reply
  end

  def accounting_update(request)
    request[:username] || raise("BUG: Missing 'username'")
    request[:sessionid] || raise("BUG: Missing 'sessionid'")
    request[:ip] || raise("BUG: Missing 'ip'")
    request[:mac] || raise("BUG: Missing 'mac'")
    request[:session_time] || raise("BUG: Missing 'session_time'")
    request[:session_uploaded_octets] || raise("BUG: Missing 'session_uploaded_octets'")
    request[:session_downloaded_octets] || raise("BUG: Missing 'session_downloaded_octets'")
    request[:session_uploaded_packets] || raise("BUG: Missing 'session_uploaded_packets'")
    request[:session_downloaded_packets] || raise("BUG: Missing 'session_downloaded_packets'")
    request[:radius] ||= false

    nas_ip_address = InetUtils.get_source_address(host)

    begin
      req = Radiustar::Request.new("#{self.host}:#{self.port}",
                                   {
                                       :dict => @@dictionary,
                                       :reply_timeout =>  DEFAULT_REQUEST_TIMEOUT,
                                       :retries_number => DEFAULT_REQUEST_RETRIES
                                   }
      )
      reply = req.accounting_update(request[:username],
                                    self.shared_secret,
                                    request[:sessionid],
                                    @@acct_custom_attr.merge(
                                        {
                                            'NAS-IP-Address' => nas_ip_address,
                                            'NAS-Identifier' => captive_portal.name,
                                            'Framed-IP-Address' => request[:ip],
                                            'Calling-Station-Id' => request[:mac],
                                            'Called-Station-Id' => captive_portal.cp_interface,
                                            'Acct-Status-Type' => 'Alive',
                                            'Acct-Authentic' => request[:radius] ? 'RADIUS' : 'Local',
                                            'Acct-Session-Time' => request[:session_time],
                                            'Acct-Input-Octets' => request[:session_uploaded_octets],
                                            'Acct-Input-Packets' => request[:session_uploaded_packets],
                                            'Acct-Output-Octets' => request[:session_downloaded_octets],
                                            'Acct-Output-Packets' => request[:session_downloaded_packets]
                                        }
                                    )
      )
    rescue Exception => e
      Rails.logger.error("Failed to send RADIUS accounting update request to #{self.host}:#{self.port} for user #{request[:username]}, sessionid #{request[:sessionid]} (#{e})")
      reply = false
    end
    reply
  end

  def accounting_stop(request)
    request[:username] || raise("BUG: Missing 'username'")
    request[:sessionid] || raise("BUG: Missing 'sessionid'")
    request[:ip] || raise("BUG: Missing 'ip'")
    request[:mac] || raise("BUG: Missing 'mac'")
    request[:session_time] || raise("BUG: Missing 'session_time'")
    request[:session_uploaded_octets] || raise("BUG: Missing 'session_uploaded_octets'")
    request[:session_downloaded_octets] || raise("BUG: Missing 'session_downloaded_octets'")
    request[:session_uploaded_packets] || raise("BUG: Missing 'session_uploaded_packets'")
    request[:session_downloaded_packets] || raise("BUG: Missing 'session_downloaded_packets'")
    request[:termination_cause] ||= 'Unknown'
    request[:radius] ||= false

    nas_ip_address = InetUtils.get_source_address(host)

    begin
      req = Radiustar::Request.new("#{self.host}:#{self.port}",
                                   {
                                       :dict => @@dictionary,
                                       :reply_timeout =>  DEFAULT_REQUEST_TIMEOUT,
                                       :retries_number => DEFAULT_REQUEST_RETRIES
                                   }
      )
      reply = req.accounting_stop(request[:username],
                                  self.shared_secret,
                                  request[:sessionid],
                                  @@acct_custom_attr.merge(
                                      {
                                          'NAS-IP-Address' => nas_ip_address,
                                          'NAS-Identifier' => captive_portal.name,
                                          'Framed-IP-Address' => request[:ip],
                                          'Calling-Station-Id' => request[:mac],
                                          'Called-Station-Id' => captive_portal.cp_interface,
                                          'Acct-Status-Type' => 'Stop',
                                          'Acct-Authentic' => request[:radius] ? 'RADIUS' : 'Local',
                                          'Acct-Session-Time' => request[:session_time],
                                          'Acct-Input-Octets' => request[:session_uploaded_octets],
                                          'Acct-Input-Packets' => request[:session_uploaded_packets],
                                          'Acct-Output-Octets' => request[:session_downloaded_octets],
                                          'Acct-Output-Packets' => request[:session_downloaded_packets],
                                          'Acct-Terminate-Cause' => request[:termination_cause]
                                      }
                                  )
      )
    rescue Exception => e
      Rails.logger.error("Failed to send RADIUS accounting stop request to #{self.host}:#{self.port} for user #{request[:username]}, sessionid #{request[:sessionid]} (#{e})")
      reply = false
    end
    reply
  end

end
