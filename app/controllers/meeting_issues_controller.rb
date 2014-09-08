class MeetingIssuesController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create]
  before_filter :new_issue, only: [:new, :create]
  before_filter :require_meeting_manager

  helper :watchers
  include WatchersHelper

  def new
    @issue.attributes = {
      assigned_to: @object.user,
      start_date: @object.start_date,
      due_date: @object.due_date,
      tracker_id: Setting[:plugin_redmine_meeting][:issue_tracker],
      description: @object.description,
      priority: @object.meeting_agenda.priority,
      estimated_hours: 1.0,
      status: IssueStatus.default,
      author: User.current

    }
  end

  def create

    @issue.watcher_user_ids = params[:meeting_pending_issue][:watcher_user_ids]
    if @issue.save
      @issue.update_attribute(:description,
        @issue.description + "\n\n" +
        t(:message_description_protocol_information, url: url_for(controller: 'meeting_protocols', action: 'show', id: @object.meeting_protocol_id))
      )
      @object.update_attribute(:issue_id, nil)
      @object.update_attribute(:issue_type, :new)
    else
      render action: :new
    end
  end

  def destroy
    @object = case params[:meeting_answer_type]
      when 'MeetingAnswer'
        MeetingAnswer.find(params[:id])
      when 'MeetingExtraAnswer'
        MeetingExtraAnswer.find(params[:id])
      end
    @object.pending_issue.destroy
    @object.update_attribute(:issue_id, nil)
    @object.update_attribute(:issue_type, nil)
  end

  def update
    @object = case params[:meeting_answer_type]
      when 'MeetingAnswer'
        MeetingAnswer.find(params[:id])
      when 'MeetingExtraAnswer'
        MeetingExtraAnswer.find(params[:id])
      end
    issue = @object.question_issue
    if update_issue(issue).valid?
      @object.update_attribute(:issue_type, :update)
      @object.update_attribute(:issue_id, issue.id)
    end
  end

private
  def new_issue
    @issue = MeetingPendingIssue.new(params[:meeting_pending_issue])
    @issue.meeting_container = @object
    
 end

  def find_object
    @object = case params[:meeting_answer_type]
      when 'MeetingAnswer'
        MeetingAnswer.find(params[:meeting_answer_id])
      when 'MeetingExtraAnswer'
        MeetingExtraAnswer.find(params[:meeting_answer_id])
      end
  end

  def key_words
    {
      id: @object.meeting_protocol_id.to_s,
      subject: @object.meeting_agenda.subject,
      meet_on: format_date(@object.meeting_agenda.meet_on),
      start_date: format_date(@object.start_date),
      due_date: format_date(@object.due_date),
      start_time: format_time(@object.meeting_agenda.start_time),
      end_time: format_time(@object.meeting_agenda.end_time),
      question: @object.meeting_question.to_s,
      description: @object.description,
      assigned_to: @object.user.name,
      place: @object.meeting_agenda.place_or_address,
      url: meeting_protocol_url(@object.meeting_protocol)
    }
  end

  def put_key_words(template)
    key_words.inject(template){ |result, key_word|
      result.gsub("%#{key_word[0]}%", key_word[1])
    }
  end

  def issue_note
    put_key_words(Setting[:plugin_redmine_meeting][:note])
  end

  def update_issue(issue)
    MeetingPendingIssue.create(
      issue_note: issue_note,
      author_id: User.current.id,
#      issue_id: issue.id,
#      issue_type: :update,
      meeting_container_id: @object.id,
      meeting_container_type: @object.class.to_s
    )
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
