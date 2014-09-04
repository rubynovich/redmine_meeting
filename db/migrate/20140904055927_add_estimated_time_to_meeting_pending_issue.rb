class AddEstimatedTimeToMeetingPendingIssue < ActiveRecord::Migration
  def change
    add_column :meeting_pending_issues, :estimated_hours, :float
  end
end
