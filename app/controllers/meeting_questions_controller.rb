class MeetingQuestionsController < ApplicationController
  unloadable

  helper :meeting_comments
  include MeetingCommentsHelper
  before_filter :require_meeting_manager

  def update
    @question = MeetingQuestion.find(params[:id])
    @object = @question.meeting_agenda
    if params[:meeting_question] && params[:meeting_question][:move_to]
      @question.move_to = params[:meeting_question][:move_to]
      @question.save
#      redirect_back_or_default controller: 'meeting_agendas', action: 'show', id: @object.meeting_agenda_id
    end
  end

private

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
