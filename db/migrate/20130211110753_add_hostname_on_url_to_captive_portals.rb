class AddHostnameOnUrlToCaptivePortals < ActiveRecord::Migration
  def self.up
    add_column :captive_portals, :hostname_on_url, :boolean, :default => false
  end

  def self.down
    remove_column :captive_portals, :hostname_on_url
  end
end
