class AddIsExternalAndExternalCompanyIdToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :is_external, :boolean, default: false
    add_column :meeting_agendas, :external_company_id, :integer
    add_index :meeting_agendas, :external_company_id
  end
end
