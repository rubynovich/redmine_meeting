class AddSendNoticesOnToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :send_notices_on, :datetime
  end
end
