class AddSawProtocolOnToMeetingParticipators < ActiveRecord::Migration
  def change
    add_column :meeting_participators, :saw_protocol_on, :datetime
  end
end
