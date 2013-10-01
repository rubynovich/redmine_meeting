class MeetingRoomSelectorsController < ApplicationController
  unloadable

  def autocomplete_for_meeting_room
    q = (params[:q] || params[:term]).to_s.strip
    @rooms = MeetingRoom.open.
      where("LOWER(name) LIKE LOWER(?)", "%#{q}%")

    render layout: false
  end

  def create
    @room = MeetingRoom.open.find(params[:meeting_room_id])
  end
end
