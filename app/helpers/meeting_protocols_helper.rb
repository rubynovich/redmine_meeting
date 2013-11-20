module MeetingProtocolsHelper
  def author_id_for_select
    User.where("#{User.table_name}.id IN (SELECT #{MeetingAgenda.table_name}.author_id FROM #{MeetingAgenda.table_name})").all(:order => [:lastname, :firstname])
  end

  def project_id_for_select
    Project.active
  end

  def time_periods_for_select
    MeetingProtocol.time_periods
  end

  def meeting_member?
    User.current.meeting_member?
  end

  def meeting_manager?
    User.current.meeting_manager?
  end

  def meeting_participator?
    User.current.meeting_participator?
  end

  def admin?
    User.current.admin?
  end

  def author?(item)
    item.author == User.current
  end

  def member?(item)
    item.users.include?(User.current)
  end

  def approver?(item)
    item.approvers.include?(User.current)
  end

  def watcher?(item)
    item.watchers.include?(User.current)
  end

  def link_to_agenda(item)
    if can_show_agenda?(item)
      link_to "#{t(:label_meeting_agenda)} ##{item.meeting_agenda_id}", controller: 'meeting_agendas', action: 'show', id: item.meeting_agenda_id
    else
      "#{t(:label_meeting_agenda)} ##{item.meeting_agenda_id}"
    end
  end

  def link_to_question_issue(answer)
    if answer.question_issue.present?
      link_to_issue(answer.question_issue, project: false, tracker: false, subject: false) +
        if can_bind_issue?(answer)
          link_to("", {controller: 'meeting_bind_issues', action: 'new', meeting_answer_type: answer.class, meeting_answer_id: answer.id}, remote: true, class: 'icon icon-edit hide-when-print')
        else
          ""
        end
    else
      if can_bind_issue?(answer)
        link_to(t(:button_add), {controller: 'meeting_bind_issues', action: 'new', meeting_answer_type: answer.class, meeting_answer_id: answer.id}, remote: true, class: 'icon icon-add hide-when-print')
      else
        ""
      end
    end
  end


  def link_to_reporter(answer)
    if answer.reporter_id_is_contact?
      link_to_contact answer.external_reporter
    else
      link_to_user answer.reporter
    end
  end

  def link_to_assigned_to(answer)
    if answer.user_id_is_contact?
      link_to_contact answer.external_user
    else
      link_to_user answer.user
    end
  end

  def link_to_meeting_notice(user)
    item = @object.meeting_participators.select{ |m| m.user == user }.first
    if item.try(:issue).present?
      if item.status == IssueStatus.default
        link_to t(:label_meeting_notice_blank), controller: 'issues', action: 'show', id: item.issue_id
      else
        link_to t(:label_meeting_notice_present), controller: 'issues', action: 'show', id: item.issue_id
      end
    else
      t(:label_meeting_notice_extra)
    end
  end

  def member_status(member)
    if member.meeting_participator.try(:user) == member.user
      t(:label_meeting_member_present)
    else
      t(:label_meeting_member_blank)
    end
  end

  def protocol_status(item)
    if item.meeting_answers.all?(&:issue)
      if item.issues.all?(&:closed?)
        t(:label_meeting_project_is_done)
      else
        t(:label_meeting_project_not_completed)
      end
    else
      t(:label_meeting_project_is_not_full)
    end
  end

  def can_send_notices?(protocol)
    (admin? || meeting_manager? && author?(protocol)) &&
      (protocol.meeting_agenda.meet_on < Date.today) ||
      (protocol.meeting_agenda.meet_on == Date.today) &&
      (protocol.meeting_agenda.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  end

  def can_show_agenda?(protocol)
    admin? || meeting_manager? || member?(protocol) || approver?(protocol.meeting_agenda)
  end

  def can_create_protocol?(protocol)
    item = protocol.meeting_agenda
    (admin? || meeting_manager?) && item.meet_on && (
      (item.meet_on < Date.today) ||
      (item.meet_on == Date.today) && (item.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
    )
  end

  def can_show_protocol?(protocol)
    admin? || meeting_manager? || member?(protocol) || approver?(protocol) || watcher?(protocol)
  end

  def can_update_protocol?(protocol)
    admin? || meeting_manager? && author?(protocol)
  end

  def can_destroy_protocol?(protocol)
    admin? || meeting_manager? && author?(protocol)
  end

  def can_create_agenda?
    admin? || meeting_manager?
  end

#  def can_show_comments?(answer)
#    admin? || meeting_manager? || answer.users.include?(User.current)
#  end

#  def can_create_comments?(answer)
#    admin? || meeting_manager? || answer.users.include?(User.current)
#  end

#  def can_create_issue?(answer)
#    admin? || meeting_manager? && author?(answer.meeting_protocol)
#  end

#  def can_update_issue?(answer)
#    (admin? || meeting_manager? && author?(answer.meeting_protocol)) && answer.meeting_question.present? && answer.meeting_question.issue.present?
#  end

#  def can_destroy_issue?(answer)
#    admin? || meeting_manager? && author?(answer.meeting_protocol)
#  end
end
