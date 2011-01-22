class CreateLocalUsers < ActiveRecord::Migration
  def self.up
    create_table :local_users do |t|
      t.string :username,                 :null => false
      t.string :password,                 :null => false
      t.integer :max_upload_bandwidth,    :null => true
      t.integer :max_download_bandwidth,  :null => true
      t.boolean :disabled,                :null => false, :default => FALSE
      t.string  :disabled_message,        :null => true, :default =>""
      t.boolean :allow_concurrent_login,  :null => false, :default => FALSE
      
      t.belongs_to :captive_portal

      t.timestamps
    end

    add_index :local_users, :username

  end

  def self.down
    drop_table :local_users
  end
end
