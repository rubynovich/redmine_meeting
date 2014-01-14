class AddAssertedToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :asserted, :boolean, default: false
  end
end
