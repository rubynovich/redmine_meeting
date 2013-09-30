class AddMeetingRoomReserveIdToMeetingAgenda < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :meeting_room_reserve_id, :integer
  end
end
