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
