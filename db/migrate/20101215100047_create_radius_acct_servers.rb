class CreateRadiusAcctServers < ActiveRecord::Migration
  def self.up
    create_table :radius_acct_servers do |t|
      t.string :host,           :null => false
      t.integer :port,          :null => false
      t.string :shared_secret,  :null => false

      t.belongs_to :captive_portal

      t.timestamps
    end

    add_index :radius_acct_servers, :host

  end

  def self.down
    drop_table :radius_acct_servers
  end
end
