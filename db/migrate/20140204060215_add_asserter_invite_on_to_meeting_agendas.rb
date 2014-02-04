class AddAsserterInviteOnToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :asserter_invite_on, :datetime
  end
end
