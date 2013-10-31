class AddMeetingCompanyToMeetingAgendas < ActiveRecord::Migration
  def up
    add_column :meeting_agendas, :meeting_company_id, :integer
    MeetingAgenda.update_all(meeting_company_id: MeetingCompany.first)
  end

  def down
    remove_column :meeting_agendas, :meeting_company_id
  end
end
