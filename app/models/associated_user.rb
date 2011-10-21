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

end
