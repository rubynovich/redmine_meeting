class AddPositionToMeetingQuestions < ActiveRecord::Migration
  def change
    add_column :meeting_questions, :position, :integer, default: true
  end
end
