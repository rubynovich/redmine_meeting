class CreateMeetingParticipators < ActiveRecord::Migration
  def change
    create_table :meeting_participators do |t|
      t.references :meeting_member
      t.references :meeting_protocol
      t.references :user
      t.references :issue
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_participators, :issue_id
    add_index :meeting_participators, :meeting_member_id
    add_index :meeting_participators, :meeting_protocol_id
    add_index :meeting_participators, :user_id
  end
end
