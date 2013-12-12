class MeetingContactInvitesController < ApplicationController
  unloadable


  def new
    @object = case params[:meeting_container_type]
    when 'MeetingAgenda'
      MeetingAgenda.find(params[:meeting_container_id])
    when 'MeetingProtocol'
      MeetingProtocol.find(params[:meeting_container_id])
    end
  end

  def create

    render text: params.inspect
  end
end
