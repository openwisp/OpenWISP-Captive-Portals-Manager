class CreateOperators < ActiveRecord::Migration
  def self.up
    create_table :operators do |t|
      t.string    :login,               :null => false
      t.string    :email,               :null => false
      t.string    :crypted_password,    :null => false
      t.string    :password_salt,       :null => false
      t.string    :persistence_token,   :null => false
      #t.string    :single_access_token, :null => false                # optional, see Authlogic::Session::Params
      #t.string    :perishable_token,    :null => false                # optional, see Authlogic::Session::Perishability

      # magic fields (all optional, see Authlogic::Session::MagicColumns)
      t.integer   :login_count,         :null => false, :default => 0
      t.integer   :failed_login_count,  :null => false, :default => 0
      t.datetime  :last_request_at
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.string    :current_login_ip
      t.string    :last_login_ip

      t.timestamps
    end

    add_index :operators, ["login"], :name => "index_operators_on_login", :unique => true
    add_index :operators, ["email"], :name => "index_operators_on_email", :unique => true
    add_index :operators, ["persistence_token"], :name => "index_operators_on_persistence_token", :unique => true

  end

  def self.down
    drop_table :operators
  end
end
