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

  def author?
    @object.author == User.current
  end

  def can_create_protocol?(item)
    meeting_manager? && (item.meet_on > Date.today)||(item.meet_on == Date.today) && (item.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  end
end
