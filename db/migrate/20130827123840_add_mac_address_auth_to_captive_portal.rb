class AddMacAddressAuthToCaptivePortal < ActiveRecord::Migration
  def self.up
    add_column :captive_portals, :mac_address_auth, :boolean
    add_column :captive_portals, :mac_address_auth_shared_secret, :string, :default => SecureRandom.hex
  end

  def self.down
    remove_column :captive_portals, :mac_address_auth
    remove_column :captive_portals, :mac_address_auth_shared_secret
  end
end
