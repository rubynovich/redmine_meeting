class MeetingBindIssuesController < ApplicationController
  unloadable

  helper :meeting_protocols
  include MeetingProtocolsHelper

  def new
    @question = MeetingQuestion.find(params[:meeting_question_id])
  end

  def create
    @question = MeetingQuestion.find(params[:meeting_question_id])
    unless @question.update_attributes(params[:meeting_question])
      render action: 'new'
    end
  end
end
