class AddSendedNoticeOnToMeetingParticipators < ActiveRecord::Migration
  def change
    add_column :meeting_participators, :sended_notice_on, :datetime
    remove_column :meeting_protocols, :send_notices_on
  end
end
