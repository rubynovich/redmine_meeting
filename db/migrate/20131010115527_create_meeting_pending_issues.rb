class CreateMeetingPendingIssues < ActiveRecord::Migration
  def change
    create_table :meeting_pending_issues do |t|
      t.integer :assigned_to_id
      t.date :start_date
      t.date :due_date
      t.integer :tracker_id
      t.text :description
      t.integer :author_id
      t.integer :parent_issue_id
      t.text :watcher_user_ids
      t.integer :issue_id
      t.string :issue_type
      t.text :issue_note
      t.integer :meeting_container_id
      t.string  :meeting_container_type
      t.boolean  :executed
      t.datetime :executed_on
      t.datetime :updated_on
      t.datetime :created_on
    end
  end
end
