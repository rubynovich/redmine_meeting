class AddAssertedToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :asserted, :boolean, default: false
  end
end
