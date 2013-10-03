class AddQuestionIssueToMeetingAnswers < ActiveRecord::Migration
  def change
    add_column :meeting_answers, :question_issue_id, :integer
    add_column :meeting_extra_answers, :question_issue_id, :integer
  end
end
