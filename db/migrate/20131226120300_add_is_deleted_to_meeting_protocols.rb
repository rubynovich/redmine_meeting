class AddIsDeletedToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :is_deleted, :boolean, default: false
  end
end
