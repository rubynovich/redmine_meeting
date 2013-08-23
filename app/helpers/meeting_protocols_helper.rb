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
end
