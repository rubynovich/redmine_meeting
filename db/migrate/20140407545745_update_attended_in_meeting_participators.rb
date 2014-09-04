class UpdateAttendedInMeetingParticipators < ActiveRecord::Migration
  def change
    MeetingParticipator.update_all(attended: true)
  end
end
