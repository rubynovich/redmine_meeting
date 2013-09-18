class AddProjectIdToMeetingQuestions < ActiveRecord::Migration
  def change
    add_column :meeting_questions, :project_id, :integer
    add_index :meeting_questions, :project_id
  end
end
