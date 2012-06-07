class AddUniqueIndexForCpSessionTokenToOnlineUsers < ActiveRecord::Migration
  def self.up
    add_index :online_users, [:cp_session_token], :unique => true, :name => "__cps"
  end

  def self.down
    remove_index :inline_users, :name => "__cps"
  end
end
