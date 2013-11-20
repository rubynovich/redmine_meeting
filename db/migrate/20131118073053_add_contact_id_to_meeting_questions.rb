class AddContactIdToMeetingQuestions < ActiveRecord::Migration
  def change
    add_column :meeting_questions, :contact_id, :integer
  end
end
