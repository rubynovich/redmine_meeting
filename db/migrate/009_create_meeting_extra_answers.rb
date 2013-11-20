class CreateMeetingExtraAnswers < ActiveRecord::Migration
  def change
    create_table :meeting_extra_answers do |t|
      t.integer  :meeting_protocol_id
      t.string   :meeting_question_name
      t.text     :description
      t.integer  :reporter_id
      t.boolean  :reporter_id_is_contact
      t.integer  :external_reporter_id
      t.integer  :user_id
      t.boolean  :user_id_is_contact
      t.integer  :external_user_id
      t.integer  :issue_id
      t.integer  :question_issue_id
      t.string   :issue_type
      t.date     :start_date
      t.date     :due_date
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_extra_answers, :user_id
    add_index :meeting_extra_answers, :issue_id
    add_index :meeting_extra_answers, :reporter_id
    add_index :meeting_extra_answers, :meeting_protocol_id
  end
end
