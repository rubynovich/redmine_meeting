class CreateMeetingPendingIssues < ActiveRecord::Migration
  def change
    create_table :meeting_pending_issues do |t|
      t.integer :assigned_to_id
      t.integer :tracker_id
      t.integer :status_id
      t.integer :project_id
      t.integer :priority_id
      t.integer :author_id
      t.integer :parent_issue_id
      t.integer :meeting_container_id
      t.string  :meeting_container_type
      t.date :start_date
      t.date :due_date
      t.string :subject
      t.text :description
      t.text :watcher_user_ids
      t.text :issue_note
      t.boolean  :executed
      t.datetime :executed_on
      t.datetime :updated_on
      t.datetime :created_on
    end
  end
end
