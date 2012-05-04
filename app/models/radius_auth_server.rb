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

class RadiusAuthServer < RadiusServer
  set_table_name :radius_auth_servers

  belongs_to :captive_portal

  attr_accessible :host, :port, :shared_secret

  DEFAULT_PORT = 1812

  CODE = {
      :Access_accept => 'Access-Accept',
      :Access_reject => 'Access-Reject'
  }

  @@auth_custom_attr = {
      'NAS-Port'        => 0,
      'NAS-Port-Type'   => 'Ethernet',
      'Service-Type'    => 'Login-User'
  }

  def initialize(options = {})
    options[:port] ||= DEFAULT_PORT
    super(options)
  end

  def authenticate(request)
    request[:username] || raise("BUG: Missing 'username'")
    request[:password] || raise("BUG: Missing 'password'")
    request[:ip] || raise("BUG: Missing 'ip'")
    request[:mac] || raise("BUG: Missing 'mac'")

    nas_ip_address = InetUtils.get_source_address(host)

    begin
      req = Radiustar::Request.new("#{host}:#{port}",
                                   {
                                       :dict => @@dictionary,
                                       :reply_timeout =>  DEFAULT_REQUEST_TIMEOUT,
                                       :retries_number => DEFAULT_REQUEST_RETRIES
                                   }
      )
      reply = req.authenticate(request[:username],
                               request[:password],
                               self.shared_secret,
                               @@auth_custom_attr.merge(
                                   {
                                       'NAS-IP-Address' => nas_ip_address,
                                       'NAS-Identifier' => captive_portal.name,
                                       'Framed-IP-Address' => request[:ip],
                                       'Calling-Station-Id' => request[:mac],
                                       'Called-Station-Id' => captive_portal.cp_interface
                                   }
                               )
      )
    rescue Exception => e
      Rails.logger.error "Error sending RADIUS authentication request to #{host}:#{port} for user #{request[:username]} (#{e})"
      return { :authenticated => false, :message => "RADIUS internal error" }
    end

    { :authenticated => (reply[:code] == RadiusAuthServer::CODE[:Access_accept]),
      :message => reply['Reply-Message'].nil? ? nil : reply['Reply-Message'].value,
      :max_upload_bandwidth => reply['WISPr-Bandwidth-Max-Up'].nil? ? nil : reply['WISPr-Bandwidth-Max-Up'].value,
      :max_download_bandwidth => reply['WISPr-Bandwidth-Max-Down'].nil? ? nil : reply['WISPr-Bandwidth-Max-Down'].value,
      :idle_timeout => reply['Idle-Timeout'].nil? ? nil : reply['Idle-Timeout'].value,
      :session_timeout => reply['Session-Timeout'].nil? ? nil : reply['Session-Timeout'].value
    }
  end
end
