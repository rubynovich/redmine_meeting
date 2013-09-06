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

  def link_to_agenda(item)
    if can_show_agenda?(item)
      link_to "#{t(:label_meeting_agenda)} ##{item.meeting_agenda_id}", controller: 'meeting_agendas', action: 'show', id: item.meeting_agenda_id
    else
      "#{t(:label_meeting_agenda)} ##{item.meeting_agenda_id}"
    end
  end

  def link_to_question_issue(question)
    if question.try(:issue).present?
      link_to_issue question.issue, project: false, tracker: false, subject: false
    else
      t(:label_meeting_question_issue_missing)
    end
  end

  def link_to_reporter(answer)
    if answer.reporter.present?
      link_to_user answer.reporter
    elsif answer.meeting_question.present? && answer.meeting_question.user.present?
      link_to_user answer.meeting_question.user
    end
  end

  def link_to_meeting_notice(item)
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
    admin? || meeting_manager? || protocol.users.include?(User.current)
  end

  def can_create_protocol?(protocol)
    item = protocol.meeting_agenda
    (admin? || meeting_manager?) && item.meet_on && (
      (item.meet_on < Date.today) ||
      (item.meet_on == Date.today) && (item.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
    )
  end

  def can_show_protocol?(protocol)
    admin? || meeting_manager? || protocol.users.include?(User.current)
  end

  def can_update_protocol?(protocol)
    admin? || meeting_manager? && author?(protocol)
  end

  def can_destroy_protocol?(protocol)
    admin? || meeting_manager? && author?(protocol)
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
