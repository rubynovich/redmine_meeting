class MeetingIssuesController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create]

  def new
    @issue = Issue.new
    @issue.assigned_to = @object.user
    @issue.start_date = @object.start_date
    @issue.due_date = @object.due_date
    @issue.tracker_id = Setting[:plugin_redmine_meeting][:issue_tracker]
    @issue.description = @object.description
  end

private

  def find_object
    @object = MeetingAnswer.find(params[:meeting_answer_id])
  end
end
