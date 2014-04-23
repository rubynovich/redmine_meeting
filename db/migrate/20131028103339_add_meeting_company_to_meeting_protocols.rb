class AddMeetingCompanyToMeetingProtocols < ActiveRecord::Migration
  def up
    #add_column :meeting_protocols, :meeting_company_id, :integer
    MeetingProtocol.update_all(meeting_company_id: MeetingCompany.first)
  end

  def down
    #remove_column :meeting_protocols, :meeting_company_id
  end
end
