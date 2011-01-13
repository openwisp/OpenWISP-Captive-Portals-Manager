class CreateAllowedTraffics < ActiveRecord::Migration
  def self.up
    create_table :allowed_traffics do |t|
      t.string :protocol,           :null => true
      t.string :source_mac_address, :null => true
      t.string :source_host,        :null => true
      t.integer :source_port,       :null => true
      t.string :destination_host,   :null => true
      t.integer :destination_port,  :null => true

      t.belongs_to :captive_portal

      t.timestamps
    end

    add_index :allowed_traffics, :source_mac_address
    add_index :allowed_traffics, :source_host
    add_index :allowed_traffics, :destination_host

  end

  def self.down
    drop_table :allowed_traffics
  end
end
