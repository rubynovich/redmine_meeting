class MeetingBindIssuesController < ApplicationController
  unloadable

  helper :meeting_protocols
  include MeetingProtocolsHelper
  helper :meeting_issues
  include MeetingIssuesHelper

  before_filter :find_answer, only: [:new, :create]

  def create
    unless @answer.update_attributes(params[params[:meeting_answer_type].underscore])
      render action: 'new'
    end
  end

private

  def find_answer
    @answer = case params[:meeting_answer_type]
      when 'MeetingAnswer'
        MeetingAnswer
      when 'MeetingExtraAnswer'
        MeetingExtraAnswer
    end.find(params[:meeting_answer_id])
  end
end
