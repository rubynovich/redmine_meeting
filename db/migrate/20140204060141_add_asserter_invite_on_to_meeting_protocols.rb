class AddAsserterInviteOnToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :asserter_invite_on, :datetime
  end
end
