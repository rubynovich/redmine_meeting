module MeetingAgendasHelper
  def author_id_for_select
    User.where("#{User.table_name}.id IN (SELECT #{MeetingAgenda.table_name}.author_id FROM #{MeetingAgenda.table_name})").all(:order => [:lastname, :firstname])
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
    item.author == User.current
  end

  def link_to_protocol(item)
    if item.meeting_protocol.present?
      if can_show_protocol?(item.meeting_protocol)
        link_to "#{t(:label_meeting_protocol)} ##{item.meeting_protocol.id}", controller: 'meeting_protocols', action: 'show', id: item.meeting_protocol.id
      else
        "#{t(:label_meeting_protocol)} ##{item.meeting_protocol.id}"
      end
    elsif can_create_protocol?(item)
      link_to t(:button_add), {controller: 'meeting_protocols', action: 'new', meeting_protocol: {meeting_agenda_id: item.id}}, {class: 'icon icon-add'}
    end
  end

  def can_create_protocol?(agenda)
    (meeting_manager? || admin?) &&
      agenda.meet_on && (
        (agenda.meet_on < Date.today) ||
        (agenda.meet_on == Date.today) && (agenda.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
      )
  end

  def can_send_invites?(agenda)
    (meeting_manager? && author?(agenda) || admin?) &&
      agenda.meet_on.present? && (agenda.meet_on >= Date.today)
  end

  def can_show_agenda?(agenda)
    admin? || meeting_manager? || agenda.users.include?(User.current)
  end

  def can_create_agenda?
    admin? || meeting_manager?
  end

  def can_update_agenda?(agenda)
    (admin? || meeting_manager? && author?(agenda)) && agenda.meeting_protocol.blank?
  end

  def can_destroy_agenda?(agenda)
    (admin? || meeting_manager? && author?(agenda)) && agenda.meeting_protocol.blank?
  end

#  def can_show_comments?(question)
#    admin? || meeting_manager? || item.users.include?(User.current)
#  end

#  def can_create_comments?(question)
#    meeting_manager? || item.users.include?(User.current)
#  end

  def can_show_protocol?(protocol)
    meeting_manager? || protocol.users.include?(User.current)
  end
end
