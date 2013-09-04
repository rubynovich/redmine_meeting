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

  def author?(item)
    item.author == User.current
  end

  def can_send_notices?
    (@object.meeting_agenda.meet_on < Date.today) ||
      (@object.meeting_agenda.meet_on == Date.today) &&
      (@object.meeting_agenda.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  end
end
