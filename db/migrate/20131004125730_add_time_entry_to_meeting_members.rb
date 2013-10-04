class AddTimeEntryToMeetingMembers < ActiveRecord::Migration
  def change
    add_column :meeting_members, :time_entry_id, :integer
  end
end
