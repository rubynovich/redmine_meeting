class MeetingIssuesController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create]
  before_filter :new_issue, only: [:new, :create]
  before_filter :require_meeting_manager

  def new
    @issue.assigned_to = @object.user
    @issue.start_date = @object.start_date
    @issue.due_date = @object.due_date
    @issue.tracker_id = Setting[:plugin_redmine_meeting][:issue_tracker]
    @issue.description = @object.description
  end

  def create
    @issue.author_id = params[:issue][:author_id]
    @issue.description += "\n\n" +
      t(:message_description_protocol_information, url: url_for(controller: 'meeting_protocols', action: 'show', id: @object.meeting_protocol_id))
    @issue.parent_issue_id = params[:issue][:parent_issue_id]
    if @issue.save
      @object.update_attribute(:issue_id, @issue.id)
      @object.update_attribute(:issue_type, :new)
    else
      render action: :new
    end
  end

  def destroy
    @object = MeetingAnswer.find(params[:id])
    if @object.issue_type == "new"
      @object.issue.update_attributes(status_id: Setting[:plugin_redmine_meeting][:issue_status])
    end
    @object.update_attribute(:issue_id, nil)
    @object.update_attribute(:issue_type, nil)
  end

  def update
   @object = MeetingAnswer.find(params[:id])
   issue = @object.meeting_question.issue
   update_issue(issue).save
   @object.update_attribute(:issue_id, issue.id)
   @object.update_attribute(:issue_type, :update)
  end

private
  def new_issue
    @issue = Issue.new(params[:issue])
  end

  def find_object
    @object = MeetingAnswer.find(params[:meeting_answer_id])
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
      place: @object.meeting_agenda.place,
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
    issue.init_journal(User.current, issue_note)
    issue.status = IssueStatus.default
    issue
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
