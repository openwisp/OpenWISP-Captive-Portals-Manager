class AddNoteToAllowedTraffics < ActiveRecord::Migration
  def self.up
    add_column :allowed_traffics, :note, :text
  end

  def self.down
    remove_column :allowed_traffics, :note
  end
end
