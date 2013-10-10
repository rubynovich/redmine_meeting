class MeetingQuestionsController < ApplicationController
  unloadable

  def update
    @object = MeetingQuestion.find(params[:id])
    if params[:meeting_question] && params[:meeting_question][:move_to]
      @object.move_to = params[:meeting_question][:move_to]
      @object.save
      redirect_back_or_default controller: 'meeting_agendas', action: 'show', id: @object.meeting_agenda_id
    end
  end
end
