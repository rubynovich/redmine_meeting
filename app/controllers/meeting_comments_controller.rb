class MeetingCommentsController < ApplicationController
  unloadable

  before_filter :new_object, only: [:new, :create]
  before_filter :find_object, only: [:destroy, :edit, :update]

  def create
    unless @object.save
      render action: :new
    end
  end

  def destroy
    @answer = @object.meeting_answer
    @object.destroy
  end

private

  def new_object
    @object = MeetingComment.new(params[:meeting_comment])
  end

  def find_object
    @object = MeetingComment.find(params[:id])
  end
end
