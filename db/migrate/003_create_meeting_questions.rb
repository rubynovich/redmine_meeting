class CreateMeetingQuestions < ActiveRecord::Migration
  def change
    create_table :meeting_questions do |t|
      t.string :title
      t.references :user
      t.references :issue
      t.references :meeting_agenda
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_questions, :user_id
    add_index :meeting_questions, :issue_id
    add_index :meeting_questions, :meeting_agenda_id
  end
end
