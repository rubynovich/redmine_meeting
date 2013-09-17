class CopyStartTimeAndEndTimeFromMeetingAgendaToMeetingProtocols < ActiveRecord::Migration
  def up
    MeetingProtocol.where("start_time = ?", nil).each do |protocol|
      protocol.update_attribute(:start_time, protocol.meeting_agenda.start_time)
    end
    MeetingProtocol.where("end_time = ?", nil).each do |protocol|
      protocol.update_attribute(:end_time, protocol.meeting_agenda.end_time)
    end
  end

  def down
  end
end
