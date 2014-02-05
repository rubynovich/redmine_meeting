class AddAssertedOnToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :asserted_on, :datetime
  end
end
