class AddAddressToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :address, :string
  end
end
