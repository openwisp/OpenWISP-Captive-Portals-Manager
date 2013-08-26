class AddCalledStationIdToOnlineUsers < ActiveRecord::Migration
  def self.up
    add_column :online_users, :called_station_id, :string
  end

  def self.down
    remove_column :online_users, :called_station_id
  end
end
