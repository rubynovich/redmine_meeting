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
end
