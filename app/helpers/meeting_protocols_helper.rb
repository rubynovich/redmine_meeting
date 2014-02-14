module MeetingProtocolsHelper
  def author_id_for_select
    User.where("#{User.table_name}.id IN (SELECT #{MeetingAgenda.table_name}.author_id FROM #{MeetingAgenda.table_name})").sorted
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
    item.author_id == User.current.id
  end

  def member?(item)
    item.user_ids.include?(User.current.id)
  end

  def approver?(item)
    item.approver_ids.include?(User.current.id)
  end

  def watcher?(item)
    item.watcher_ids.include?(User.current.id)
  end

  def asserter?(item)
    (item.asserter_id == User.current.id)
  end

  def approved?(item)
    approvers = item.meeting_approvers.deleted(false)
    approvers.blank? || (approvers.present? && approvers.all?(&:approved?))
  end

  def asserted?(item)
    item.asserted? || (item.asserter_id_is_contact? && approved?(item))
  end

  def can_send_notices?(protocol)
    (admin? || (meeting_manager? && author?(protocol))) &&
      ((protocol.meet_on < Date.today) ||
        ((protocol.meet_on == Date.today) &&
          (protocol.start_time.seconds_since_midnight < Time.now.seconds_since_midnight))) &&
      !protocol.is_deleted? &&
      asserted?(protocol)
  end

  def can_show_agenda?(protocol)
    agenda = protocol.meeting_agenda
    admin? || author?(protocol) || meeting_manager? || member?(protocol) || approver?(agenda) || asserter?(agenda)
  end

  def can_create_protocol?(protocol)
    item = protocol.meeting_agenda
    (admin? || meeting_manager?) && item.meet_on && (
      (item.meet_on < Date.today) ||
      (item.meet_on == Date.today) && (item.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
    ) &&
    asserted?(item)
  end

  def can_show_protocol?(protocol)
    admin? || (meeting_manager? && (author?(protocol) || member?(protocol) || approver?(protocol) || watcher?(protocol) || asserter?(protocol)))
  end

  def can_update_protocol?(protocol)
    (admin? ||
      (meeting_manager? &&
        (author?(protocol) || approver?(protocol) || asserter?(protocol)))) &&
    !protocol.is_deleted? &&
    (!asserted?(protocol) ||
      (protocol.meeting_approvers.open.blank? && protocol.asserter_id_is_contact?))
  end

  def can_destroy_protocol?(protocol)
    (admin? || (meeting_manager? && author?(protocol))) &&
    !protocol.is_deleted? &&
    (!asserted?(protocol) ||
      (protocol.meeting_approvers.open.blank? && protocol.asserter_id_is_contact?))
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

  def can_assert?(item)
    asserter?(item) &&
    assertable?(item)
  end

  def assertable?(item)
    !item.asserted? &&
    approved?(item) &&
    !item.asserter_id_is_contact? &&
    item.asserter.present?
  end

  def can_asserter_invite?(item)
    (admin? ||
      (meeting_manager? && author?(item))) &&
    assertable?(item) &&
    (item.asserter_id != User.current.id)
  end

  def can_restore_protocol?(item)
    (admin? || (meeting_manager? && author?(item))) &&
    item.is_deleted? &&
    item.meeting_agenda.meeting_protocol.is_deleted?
  end

  def link_to_asserter_invite(object)
    label = if object.asserter_invite_on.blank?
      l(:label_send_asserter_invite)
    else
      l(:label_resend_asserter_invite)
    end
    link_to label, {action: 'send_asserter_invite', id: object.id}, class: 'icon icon-user'
  end

  def link_to_send_notices(object)
    label = if object.meeting_participators.all?(&:sended_notice_on)
      l(:label_resend_notices)
    else
      l(:label_send_notices)
    end
    link_to label, {action: 'send_notices', id: object.id}, class: 'icon icon-issue'
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
      link_to_contact answer.external_reporter if answer.external_reporter.present?
    else
      link_to_user answer.reporter if answer.reporter.present?
    end
  end

  def link_to_assigned_to(answer)
    if answer.user_id_is_contact?
      link_to_contact answer.external_user if answer.external_user.present?
    else
      link_to_user answer.user if answer.user.present?
    end
  end

  def link_to_meeting_notice(user)
    item = @object.meeting_participators.where(user_id: user.id).first
    if item.sended_notice_on.present?
      if item.saw_protocol_on.present?
        t(:label_meeting_notice_present)
      else
        t(:label_meeting_notice_blank)
      end
    else
      t(:label_meeting_notice_extra)
    end
  end

  def link_to_address(address, company = nil)
    url = "http://maps.google.com/maps?f=q&ie=UTF8&om=1&q=#{h address.gsub("\r\n"," ").gsub("\n"," ")}"
    url += "+(#{h company.to_s.gsub(/["']+/,"")})" if company.present?
    link_to address, url
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
end
