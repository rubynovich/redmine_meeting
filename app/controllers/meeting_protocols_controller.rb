class MeetingProtocolsController < ApplicationController
  unloadable

  before_filter :find_object, only: [:edit, :show, :destroy, :update]
  before_filter :new_object, only: [:new, :create]

  def index
    @collection = model_class.order('created_on desc')
  end

  def create
#    @object.save_attachments(params[:attachments])
    if @object.save
      flash[:notice] = l(:notice_successful_create)
#      render_attachment_warning_if_needed(@object)
      redirect_to action: 'show', id: @object.id
#      redirect_to :action => :show, :id => @object.id
    else
      render action: 'new'
    end
  end

  def update
#    @object.save_attachments(params[:attachments])
    if @object.update_attributes(params[model_sym])
      flash[:notice] = l(:notice_successful_update)
#      render_attachment_warning_if_needed(@object)
      redirect_to action: 'show', id: @object.id
    else
      render action: 'edit'
    end
  end

  def new
#    @object.meeting_agenda_id = params[:meeting_agenda_id]
    @object.meeting_answers_attributes = @object.meeting_agenda.meeting_questions.map do |question|
      {meeting_question_id: question.id, user_id: question.user_id}
    end
    @object.meeting_participators_attributes = @object.meeting_agenda.meeting_members.map do |member|
      {meeting_member_id: member.id, user_id: member.user_id}
    end
  rescue
    render_403
  end

  def destroy
    flash[:notice] = l(:notice_successful_delete) if @object.destroy
    redirect_to action: 'index'
  end

private

  def model_class
    MeetingProtocol
  end

  def model_sym
    :meeting_protocol
  end

  def find_object
    @object = model_class.find(params[:id])
  end

  def new_object
    @object = model_class.new(params[model_sym])
  end
end
