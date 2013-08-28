class MeetingProtocolsController < ApplicationController
  unloadable

  before_filter :find_object, only: [:edit, :show, :destroy, :update]
  before_filter :new_object, only: [:new, :create]

  def index
    @limit = per_page_option

    @scope = model_class.joins(:meeting_agenda).
      time_period(params[:time_period_created_on], 'meeting_protocols.created_on').
      time_period(params[:time_period_meet_on], 'meeting_agendas.meet_on').
      eql_field(params[:author_id], 'meeting_protocols.author_id').
      eql_date_field(params[:created_on], 'meeting_protocols.created_on').
      eql_field(params[:meet_on], 'meeting_agendas.meet_on').
      eql_project_id(params[:project_id]).
      like_field(params[:subject], 'meeting_agendas.subject').
      uniq

    @count = @scope.count

    @pages = begin
      Paginator.new @count, @limit, params[:page]
    rescue
      Paginator.new self, @count, @limit, params[:page]
    end
    @offset ||= begin
      @pages.offset
    rescue
      @pages.current.offset
    end

    @collection = @scope.
      limit(@limit).
      offset(@offset).
#      order(sort_clause).
      order('created_on desc').
      all
  end

  def create
#    @object.save_attachments(params[:attachments])
    @object.meeting_participators_attributes = session[:meeting_participator_ids].map{ |user_id| {user_id: user_id} }
    if @object.save
      flash[:notice] = l(:notice_successful_create)
#      render_attachment_warning_if_needed(@object)
      redirect_to action: 'show', id: @object.id
#      redirect_to :action => :show, :id => @object.id
    else
      @members = User.order(:lastname, :firstname).find(session[:meeting_participator_ids])
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
      @members = @object.users
      render action: 'edit'
    end
  end

  def new
    @members = @object.meeting_agenda.users
    session[:meeting_participator_ids] = @object.meeting_agenda.user_ids
    @object.meeting_answers_attributes = @object.meeting_agenda.meeting_questions.map do |question|
      {meeting_question_id: question.id, reporter_id: question.user_id}
    end
#    @object.meeting_participators_attributes = @object.meeting_agenda.meeting_members.map do |member|
#      {meeting_member_id: member.id, user_id: member.user_id}
#    end
  rescue
    render_403
  end

  def edit
    @members = @object.users
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
