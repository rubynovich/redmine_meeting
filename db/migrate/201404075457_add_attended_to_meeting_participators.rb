class AddAttendedToMeetingParticipators < ActiveRecord::Migration
  def change
    add_column :meeting_participators, :attended, :boolean
  end
end
