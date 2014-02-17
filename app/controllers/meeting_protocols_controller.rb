class MeetingProtocolsController < ApplicationController
  unloadable

  helper :attachments
  include AttachmentsHelper
  helper :meeting_protocols
  include MeetingProtocolsHelper
  helper :meeting_issues
  include MeetingIssuesHelper
  helper :meeting_comments
  include MeetingCommentsHelper
  helper :meeting_approvers
  include MeetingApproversHelper
  helper :meeting_external_approvers
  include MeetingExternalApproversHelper
  helper :meeting_watchers
  include MeetingWatchersHelper
  helper :meeting_bind_issues
  include MeetingBindIssuesHelper
  helper :meeting_participators
  #include MeetingPatricipatorsHelper
  helper :contacts
  # include ContactsHelper

  before_filter :find_object, only: [:edit, :show, :destroy, :update,
    :send_notices, :assert, :send_asserter_invite, :restore]
  before_filter :new_object, only: [:new, :create]
  before_filter :require_meeting_manager, except: [:index, :show]

  def send_notices
    (render_403; return false) unless can_send_notices?(@object)

    if @object.send_notices
      flash[:notice] = l(:notice_successful_send_notices)
    else
      flash[:error] = l(:error_send_notices_failed)
    end

    redirect_to action: 'show', id: @object.id
  end

  def show
#    (render_403; return false) unless can_show_protocol?(@object)
    @watchers = @object.watchers
    respond_to do |format|
      format.pdf {
        filename = ("Protokol_%04d" % [@object.id]) + @object.meet_on.strftime("_%Y-%m-%d.pdf")
        send_data MeetingProtocolReport.new.to_pdf(@object), filename: filename, type: "application/pdf", disposition: "inline"
      }
      format.html
    end
  end

  def index
    @limit = per_page_option

    @scope = model_class.
      active.
      includes(:meeting_agenda).
      time_period(params[:time_period_created_on], 'meeting_protocols.created_on').
      time_period(params[:time_period_meet_on], 'meeting_agendas.meet_on').
      eql_field(params[:author_id], 'meeting_protocols.author_id').
      eql_field(params[:created_on], 'DATE(meeting_protocols.created_on)').
      eql_field(params[:meet_on], 'meeting_agendas.meet_on').
      eql_project_id(params[:project_id]).
      like_field(params[:subject], 'meeting_agendas.subject').
      bool_field(params[:is_external], 'meeting_agendas.is_external').
      uniq

    @scope = @scope.includes(:meeting_participators).includes(:meeting_answers).includes(:meeting_watchers).includes(:meeting_approvers).
      where("meeting_protocols.author_id = :user_id OR meeting_participators.user_id = :user_id OR meeting_answers.reporter_id = :user_id OR meeting_watchers.user_id = :user_id OR meeting_approvers.user_id = :user_id OR meeting_protocols.asserter_id = :user_id", user_id: User.current.id) unless admin?

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
      order('meeting_protocols.created_on desc').
      all
  end

  def new
    (render_403; return false) unless can_create_protocol?(@object)
    session[:meeting_participator_ids] = @object.meeting_agenda.user_ids
    session[:meeting_contact_ids] = @object.meeting_agenda.contact_ids
    nested_objects_from_session
    @object.meeting_company = @object.meeting_agenda.meeting_company
    @object.asserter = @object.meeting_agenda.asserter
  rescue
    render_403
  end

  def create
    (render_403; return false) unless can_create_protocol?(@object)
    @object.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    @object.meeting_participators_attributes = session[:meeting_participator_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_participator_ids].present?
    @object.meeting_contacts_attributes = session[:meeting_contact_ids].map{ |contact_id| {contact_id: contact_id} } if session[:meeting_contact_ids].present?
    @object.meeting_watchers_attributes = session[:meeting_watcher_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_watcher_ids].present?
    if @object.save
      flash[:notice] = l(:notice_successful_create)
      render_attachment_warning_if_needed(@object)
      redirect_to action: 'show', id: @object.id
    else
      nested_objects_from_session
      render action: 'new'
    end
  end

  def edit
    (render_403; return false) unless can_update_protocol?(@object)
    nested_objects_from_database
  end

  def update
    (render_403; return false) unless can_update_protocol?(@object)
    @object.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    if @object.update_attributes(params[model_sym])
      flash[:notice] = l(:notice_successful_update)
      render_attachment_warning_if_needed(@object)
      redirect_to action: 'show', id: @object.id
    else
      nested_objects_from_database
      render action: 'edit'
    end
  end

  def destroy
    (render_403; return false) unless can_destroy_protocol?(@object)
    if @object.mark_as_deleted
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to action: 'index'
  end

  def assert
    (render_403; return false) unless can_assert?(@object)
    if @object.assert
      flash[:notice] = l(:notice_successful_assert)
    end
  end

  def send_asserter_invite
    (render_403; return false) unless can_asserter_invite?(@object)
    if @object.send_asserter_invite
      flash[:notice] = l(:notice_asserter_invite_sent)
    end
    redirect_to action: 'show', id: @object.id
  end

  def restore
    (render_403; return false) unless can_restore_protocol?(@object)
    if @object.restore
      flash[:notice] = l(:notice_meeting_protocol_successful_restored)
    end
    redirect_to action: 'show', id: @object.id
  end

private

  def nested_objects_from_session
    @members = User.active.sorted.where(id: session[:meeting_participator_ids])
    @contacts = Contact.order_by_name.where(id: session[:meeting_contact_ids])
  end

  def nested_objects_from_database
    @members = @object.users
    @contacts = @object.contacts
  end

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

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
