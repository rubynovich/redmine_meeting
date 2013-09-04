class AddIssueIdToMeetingParticipator < ActiveRecord::Migration
  def change
    add_column :meeting_participators, :issue_id, :integer
    add_index :meeting_participators, :issue_id
  end
end
