class CreateOnlineUsers < ActiveRecord::Migration
  def self.up
    create_table :online_users do |t|
      t.string :username,                 :null => false
      t.string :password,                 :null => false
      t.string :cp_session_token,         :null => false
      t.string :ip_address,               :null => false
      t.string :mac_address,              :null => false
      t.integer :session_timeout,         :null => true
      t.integer :idle_timeout,            :null => true
      t.integer :uploaded_octets,         :null => false, :default => 0
      t.integer :downloaded_octets,       :null => false, :default => 0
      t.integer :uploaded_packets,        :null => false, :default => 0
      t.integer :downloaded_packets,      :null => false, :default => 0
      t.datetime :last_activity,          :null => false
      t.integer :max_upload_bandwidth,    :null => true
      t.integer :max_download_bandwidth,  :null => true
      t.boolean :radius,                  :null => false

      t.belongs_to :captive_portal,       :null => false
      
      t.timestamps
    end

    add_index :online_users, [ :captive_portal_id, :username ], :name => "__cpi_u"
    add_index :online_users, [ :captive_portal_id, :cp_session_token ], :name => "__cpi_cps"
    add_index :online_users, [ :captive_portal_id, :username, :cp_session_token ], :name => "__cpi_u_cps"

  end

  def self.down
    drop_table :online_users
  end
end
