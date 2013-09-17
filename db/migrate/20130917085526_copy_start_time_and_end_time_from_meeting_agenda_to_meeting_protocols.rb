class CopyStartTimeAndEndTimeFromMeetingAgendaToMeetingProtocols < ActiveRecord::Migration
  def up
    MeetingProtocol.where("start_time IS ?", nil).each do |protocol|
      protocol.update_attribute(:start_time, protocol.meeting_agenda.start_time) if protocol.meeting_agenda.present?
    end
    MeetingProtocol.where("end_time IS ?", nil).each do |protocol|
      protocol.update_attribute(:end_time, protocol.meeting_agenda.end_time) if protocol.meeting_agenda.present?
    end
  end

  def down
  end
end
