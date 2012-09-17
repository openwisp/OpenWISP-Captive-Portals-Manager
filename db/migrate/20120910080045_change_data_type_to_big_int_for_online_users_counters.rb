class ChangeDataTypeToBigIntForOnlineUsersCounters < ActiveRecord::Migration
  def self.up
    change_table :online_users do |t|
      t.change :uploaded_octets,    :integer, :limit => 8
      t.change :downloaded_octets,  :integer, :limit => 8
      t.change :uploaded_packets,   :integer, :limit => 8
      t.change :downloaded_packets, :integer, :limit => 8
    end
  end

  def self.down
    change_table :online_users do |t|
      t.change :uploaded_octets,    :integer
      t.change :downloaded_octets,  :integer
      t.change :uploaded_packets,   :integer
      t.change :downloaded_packets, :integer
    end
  end
end

