class AddUserIdIsContactToMeetingQuestions < ActiveRecord::Migration
  def change
    add_column :meeting_questions, :user_id_is_contact, :boolean
  end
end
