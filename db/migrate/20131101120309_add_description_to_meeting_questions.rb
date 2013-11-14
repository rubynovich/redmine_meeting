class AddDescriptionToMeetingQuestions < ActiveRecord::Migration
  def change
    add_column :meeting_questions, :description, :text
  end
end
