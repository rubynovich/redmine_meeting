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

  def author?(item)
    item.author == User.current
  end

  def link_to_protocol(protocol)
    if protocol.present?
      if can_show_protocol?(protocol)
        link_to "#{t(:label_meeting_protocol)} ##{protocol.id}", controller: 'meeting_protocols', action: 'show', id: protocol.id
      else
        "#{t(:label_meeting_protocol)} ##{protocol.id}"
      end
    elsif can_create_protocol?(protocol.meeting_agenda)
      link_to t(:button_add), {controller: 'meeting_protocols', action: 'new', meeting_protocol: {meeting_agenda_id: protocol.meeting_agenda_id}}, {class: 'icon icon-add'}
    end
  end

  def can_create_protocol?(item)
    meeting_manager? && item.meet_on && (item.meet_on < Date.today) ||
      item.meet_on && (item.meet_on == Date.today) && (item.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  end

  def can_send_invites?(item)
    item.meet_on.present? && item.meet_on >= Date.today
  end

  def can_show_agenda?(item)
    meeting_manager? || item.users.include?(User.current)
  end

  def can_create_agenda?
    meeting_manager?
  end

  def can_update_agenda?(item)
    meeting_manager? && author?(item) && item.meeting_protocol.blank?
  end

  def can_destroy_agenda?(item)
    meeting_manager? && author?(item) && item.meeting_protocol.blank?
  end

  def can_show_comments?(item)
    meeting_manager? || item.users.include?(User.current)
  end

  def can_create_comments?(item)
    meeting_manager? || item.users.include?(User.current)
  end

  def can_show_protocol?(item)
    meeting_manager? || item.users.include?(User.current)
  end
end
