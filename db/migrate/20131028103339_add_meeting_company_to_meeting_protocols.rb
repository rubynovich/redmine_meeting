class AddMeetingCompanyToMeetingProtocols < ActiveRecord::Migration
  def up
    MeetingProtocol.update_all(meeting_company_id: MeetingCompany.first)
  end

  def down
  end
end
