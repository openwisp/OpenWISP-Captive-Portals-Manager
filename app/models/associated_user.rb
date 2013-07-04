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

class AssociatedUser < ActiveResource::Base
  self.site = OWMW["url"]
  self.user = OWMW["username"]
  self.password = OWMW["password"]

  def self.site_url_by_user_mac_address(mac)
    au = AssociatedUser.find(mac)
    au.access_point.access_point_group.site_url
  rescue
    nil
  end
  
  # return access point hostname from mac address of user
  def self.access_point_hostname_by_user_mac_address(mac)
    au = AssociatedUser.find(mac)
    au.access_point.name
  rescue
    nil
  end
  
  # return access point mac address from user mac address
  # return false if OWMW is not configured
  def self.access_point_mac_address_by_user_mac_address(mac)
    # ensure OWMW is enabled
    if OWMW != {}
      # if owmw is enabled ensure is configured correctly
      if OWMW["password"].nil? or OWMW["url"].nil? or OWMW["url"].empty?
        raise "OWMW not configured correctly, check configuration for environment '#{Rails.env}'"
      end
      AssociatedUser.find(mac).access_point.mac_address
    else
      return false
    end
  end
end