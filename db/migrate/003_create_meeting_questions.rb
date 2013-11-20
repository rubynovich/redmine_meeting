class CreateMeetingQuestions < ActiveRecord::Migration
  def change
    create_table :meeting_questions do |t|
      t.string :title
      t.text :description
      t.references :user
      t.boolean :user_id_is_contact
      t.integer :external_user_id
      t.references :contact
      t.references :issue
      t.references :meeting_agenda
      t.references :project
      t.integer :position, default: true
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_questions, :user_id
    add_index :meeting_questions, :issue_id
    add_index :meeting_questions, :meeting_agenda_id
    add_index :meeting_questions, :project_id
  end
end
