class CreateCaptivePortals < ActiveRecord::Migration
  def self.up
    create_table :captive_portals do |t|
      t.string :name,                         :null => false
      t.string :cp_interface,                 :null => false
      t.string :wan_interface,                :null => false
      t.string :redirection_url,              :null => false
      t.string :error_url,                    :null => false
      t.integer :local_http_port,             :null => false
      t.integer :local_https_port,            :null => false
      t.integer :default_download_bandwidth,  :null => true
      t.integer :default_upload_bandwidth,    :null => true
      t.integer :default_session_timeout,     :null => true
      t.integer :default_idle_timeout,        :null => true
      t.integer :total_upload_bandwidth,      :null => true
      t.integer :total_download_bandwidth,    :null => true

      t.timestamps
    end

    add_index :captive_portals, :cp_interface

  end

  def self.down
    drop_table :captive_portals
  end
end
