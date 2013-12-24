class AddExternalPlaceTypeToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :external_place_type, :string, default: "external_company"
  end
end
