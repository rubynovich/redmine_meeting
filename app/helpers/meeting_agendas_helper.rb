module MeetingAgendasHelper
  def author_id_for_select
    User.where("#{User.table_name}.id IN (SELECT #{MeetingAgenda.table_name}.author_id FROM #{MeetingAgenda.table_name})").sorted
  end

  def protocol_for_select
    t(:label_protocol_for_select).invert
  end

  def project_id_for_select
    Project.active
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

  def asserter?(item)
    (item.asserter_id == User.current.id)
  end

  def approved?(item)
    approvers = item.meeting_approvers.deleted(false)
    (approvers.present? && approvers.all?(&:approved?)) || approvers.blank?
  end

  def asserted?(agenda)
    (agenda.asserted? ||
      (agenda.asserter_id_is_contact? && approved?(agenda)))
  end

  def watcher?(item)
    item.watcher_ids.include?(User.current.id)
  end

  def meeting_expected?(agenda)
    (agenda.meet_on < Date.today) ||
    ((agenda.meet_on == Date.today) &&
      (agenda.start_time.seconds_since_midnight > Time.now.seconds_since_midnight))
  end

  def can_create_protocol?(agenda)
    (meeting_manager? || admin?) &&
    agenda.meet_on &&
    !meeting_expected?(agenda) &&
    !agenda.is_deleted? &&
    asserted?(agenda)
  end

  def can_send_invites?(agenda)
    (admin? ||
      (meeting_manager? && author?(agenda))) &&
    agenda.meet_on &&
    meeting_expected?(agenda) &&
    !agenda.is_deleted? &&
    asserted?(agenda)
  end

  def can_show_agenda?(agenda)
    admin? || (meeting_manager? && (author?(agenda) || member?(agenda) || approver?(agenda) || asserter?(agenda)))
  end

  def can_create_agenda?
    admin? || meeting_manager?
  end

  def can_update_agenda?(agenda)
    (admin? ||
      (meeting_manager? &&
        (author?(agenda) || approver?(agenda) || asserter?(agenda)))) &&
    (agenda.meeting_protocol.blank? ||
      (agenda.meeting_protocol.present? && agenda.meeting_protocol.is_deleted?)) &&
    (agenda.meet_on >= Date.today) &&
    !agenda.is_deleted? &&
    (!asserted?(agenda) ||
      (agenda.meeting_approvers.open.blank? && agenda.asserter_id_is_contact?))
  end

  def can_destroy_agenda?(agenda)
    (admin? || (meeting_manager? && author?(agenda))) &&
    agenda.meeting_protocol.blank? &&
    !agenda.is_deleted? &&
    (!asserted?(agenda) ||
      (agenda.meeting_approvers.open.blank? && agenda.asserter_id_is_contact?))
  end

#  def can_show_comments?(question)
#    admin? || meeting_manager? || item.users.include?(User.current)
#  end

#  def can_create_comments?(question)
#    meeting_manager? || item.users.include?(User.current)
#  end

  def can_show_protocol?(protocol)
    admin? || (meeting_manager? && (author?(protocol) || member?(protocol) || approver?(protocol) || watcher?(protocol) || asserter?(protocol)))
  end

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

  def can_restore_agenda?(item)
    (admin? || (meeting_manager? && author?(item))) &&
    item.is_deleted?
  end

  def link_to_asserter_invite(object)
    label = if object.asserter_invite_on.blank?
      l(:label_send_asserter_invite)
    else
      l(:label_resend_asserter_invite)
    end
    link_to label, {action: 'send_asserter_invite', id: object.id}, class: 'icon icon-user'
  end

  def link_to_send_invite(object)
    if object.meeting_members.all?(&:issue)
      link_to l(:label_resend_invites), {action: 'resend_invites', id: object.id}, class: 'icon icon-issue'
    else
      link_to l(:label_send_invites), {action: 'send_invites', id: object.id}, class: 'icon icon-issue'
    end
  end

  def link_to_copy_agenda(item)
    link_to l(:button_copy), {action: 'copy', id: item.id}, class: 'icon icon-copy'
  end

  def link_to_protocol(item)
    if item.meeting_protocol.present? && !item.meeting_protocol.is_deleted?
      if can_show_protocol?(item.meeting_protocol)
        link_to("#{t(:label_meeting_protocol)} ##{item.meeting_protocol.id}",
          {controller: 'meeting_protocols', action: 'show', id: item.meeting_protocol.id})
      else
        "#{t(:label_meeting_protocol)} ##{item.meeting_protocol.id}"
      end
    elsif can_create_protocol?(item)
      if item.meeting_protocol.present? && item.meeting_protocol.is_deleted?
        link_to(t(:label_meeting_protocol_is_deleted),
          {controller: 'meeting_protocols', action: 'show', id: item.meeting_protocol.id},
          {class: 'is_deleted'})
      else
        ""
      end.html_safe +
        link_to(t(:button_add), {
          controller: 'meeting_protocols', action: 'new', meeting_protocol: {meeting_agenda_id: item.id}},
          {class: 'icon icon-add'})
    end
  end

  def link_to_address(address, company = nil)
    url = "http://maps.google.com/maps?f=q&ie=UTF8&om=1&q=#{h address.gsub("\r\n"," ").gsub("\n"," ")}"
    url += "+(#{h company.to_s.gsub(/["']+/,"")})" if company.present?
    link_to address, url
  end
end
