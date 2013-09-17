class AddStartTimeAndEndTimeToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :start_time, :time
    add_column :meeting_protocols, :end_time, :time
  end
end
