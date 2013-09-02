class AddIssueTypeToMeetingAnswers < ActiveRecord::Migration
  def change
    add_column :meeting_answers, :issue_type, :string
  end
end
