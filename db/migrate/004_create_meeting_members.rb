class CreateMeetingMembers < ActiveRecord::Migration
  def change
    create_table :meeting_members do |t|
      t.references :meeting_agenda
      t.references :user
      t.references :issue
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_members, :meeting_agenda_id
    add_index :meeting_members, :user_id
    add_index :meeting_members, :issue_id
  end
end
