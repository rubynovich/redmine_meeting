class CreateMeetingAnswers < ActiveRecord::Migration
  def change
    create_table :meeting_answers do |t|
      t.references :meeting_protocol
      t.references :meeting_question
      t.text :description
      t.references :user
      t.references :issue
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_answers, :meeting_question_id
    add_index :meeting_answers, :meeting_protocol_id
    add_index :meeting_answers, :user_id
    add_index :meeting_answers, :issue_id
  end
end
