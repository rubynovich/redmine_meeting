class CreateMeetingAnswers < ActiveRecord::Migration
  def change
    create_table :meeting_answers do |t|
      t.references :meeting_protocol
      t.references :meeting_question
      t.text :description
      t.integer :reporter_id
      t.integer :question_issue_id
      t.references :user
      t.references :issue
      t.string :issue_type
      t.date :start_date
      t.date :due_date
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_answers, :meeting_question_id
    add_index :meeting_answers, :meeting_protocol_id
    add_index :meeting_answers, :user_id
    add_index :meeting_answers, :reporter_id
    add_index :meeting_answers, :issue_id
  end
end
