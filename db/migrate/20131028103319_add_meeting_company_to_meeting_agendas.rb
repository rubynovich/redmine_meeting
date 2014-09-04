class AddMeetingCompanyToMeetingAgendas < ActiveRecord::Migration
  def up
    MeetingAgenda.update_all(meeting_company_id: MeetingCompany.first)
  end

  def down
  end
end
