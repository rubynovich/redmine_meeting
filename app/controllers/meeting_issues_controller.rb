class MeetingIssuesController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create, :destroy]
  before_filter :new_issue, only: [:new, :create]

  def new
    @issue.assigned_to = @object.user
    @issue.start_date = @object.start_date
    @issue.due_date = @object.due_date
    @issue.tracker_id = Setting[:plugin_redmine_meeting][:issue_tracker]
    @issue.description = @object.description
  end

  def create
    @issue.author = User.current
    if @issue.save
      @object.update_attribute(:issue_id, @issue.id)
    else
      render action: :new
    end
  end

  def destroy
    @object.update_attribute(:issue_id, nil)
  end

private
  def new_issue
    @issue = Issue.new(params[:issue])
  end

  def find_object
    @object = MeetingAnswer.find(params[:meeting_answer_id])
  end
end
