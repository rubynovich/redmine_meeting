class MeetingQuestionsController < ApplicationController
  unloadable

  def update
    @object = MeetingQuestion.find(params[:id])

    if @object.update_attributes(params[:meeting_question].select{|k,v| k == :move_to} )
      redirect_back_or_default controller: 'meeting_agendas', action: 'show', id: @object.meeting_agenda_id
    end

  end
end
