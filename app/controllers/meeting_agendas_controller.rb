class MeetingAgendasController < ApplicationController
  unloadable

  before_filter :find_object, only: [:edit, :show, :destroy, :update,
    :send_invites, :resend_invites, :group, :ungroup, :assert,
    :send_asserter_invite, :restore]
  before_filter :new_object, only: [:new, :create]
  before_filter :require_meeting_manager, except: [:index, :show]

  helper :attachments
  include AttachmentsHelper
  helper :meeting_agendas
  include MeetingAgendasHelper
  helper :meeting_comments
  include MeetingCommentsHelper
  helper :meeting_approvers
  include MeetingApproversHelper
  helper :meeting_external_approvers
  include MeetingExternalApproversHelper

  helper :contacts
  # include ContactsHelper

  include ApplicationHelper
  helper :meeting_watchers
  include MeetingWatchersHelper

  def show
#    (render_403; return false) unless can_show_agenda?(@object)
    @watchers = @object.watchers
    respond_to do |format|
      format.pdf {
        filename = ("Povestka_%04d" % [@object.id]) + @object.meet_on.strftime("_%Y-%m-%d.pdf")
        send_data MeetingAgendaReport.new.to_pdf(@object), filename: filename, type: "application/pdf", disposition: "inline"
      }
      format.html
    end
  end

  def group
    @watchers = @object.watchers
    session[:meeting_agenda_ungrouped] = nil

    render action: 'ungroup'
  end

  def ungroup
    @watchers = @object.watchers
    session[:meeting_agenda_ungrouped] = "true"
  end

  def send_invites
    (render_403; return false) unless can_send_invites?(@object)
    @object.meeting_members.reject(&:issue).each(&:send_invite)
    @object.meeting_contacts.each do |contact|
      begin
        Mailer.meeting_contacts_invite(contact).deliver
      rescue
        nil
      end
    end
    redirect_to controller: 'meeting_agendas', action: 'show', id: @object.id
  end

  def resend_invites
    (render_403; return false) unless can_send_invites?(@object)
    @object.meeting_members.each(&:resend_invite)
    @object.meeting_contacts.each do |contact|
      begin
        Mailer.meeting_contacts_invite(contact).deliver
      rescue
        nil
      end
    end
    redirect_to controller: 'meeting_agendas', action: 'show', id: @object.id
  end

  def autocomplete_for_issue
    q = (params[:q] || params[:term]).to_s.strip
    @issues = if q.present?
      scope = Issue.visible
      if q.match(/\A#?(\d+)\z/)
        scope.where(id: $1)
      else
        scope.where("LOWER(#{Issue.table_name}.subject) LIKE LOWER(?)", "%#{q}%").order("#{Issue.table_name}.id DESC").limit(10)
      end
    end.uniq.compact

    render layout: false
  end

  def autocomplete_for_place
    q = (params[:q] || params[:term]).to_s.strip
    places = if q.present?
      MeetingAgenda.
        where("LOWER(place) LIKE LOWER(?)", "%#{q}%").
        order(:place).
        limit(10).
        select(:place).
        uniq.
        compact.
        map{|l| { 'label' => l.place, 'value' => l.place} }
    end

    render :text => places.to_json, :layout => false
  end

  def index
    @limit = per_page_option

    @scope = model_class.
      active.
      time_period(params[:time_period_created_on], 'meeting_agendas.created_on').
      time_period(params[:time_period_meet_on], 'meeting_agendas.meet_on').
      eql_field(params[:author_id], 'meeting_agendas.author_id').
      eql_field(params[:created_on], 'DATE(meeting_agendas.created_on)').
      eql_field(params[:meet_on], 'meeting_agendas.meet_on').
      like_field(params[:subject], 'meeting_agendas.subject').
      eql_project_id(params[:project_id]).
      bool_field(params[:is_external], 'meeting_agendas.is_external').
      uniq

    @scope = @scope.includes(:meeting_members).includes(:meeting_approvers).includes(:meeting_watchers).
      where("meeting_members.user_id = :user_id OR meeting_agendas.author_id = :user_id OR meeting_approvers.user_id = :user_id OR meeting_watchers.user_id = :user_id", user_id: User.current.id) unless admin?

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
      order('meeting_agendas.created_on desc').
      all
  end

  def new
    (render_403; return false) unless can_create_agenda?
    @object.priority = IssuePriority.default
    session[:meeting_member_ids] = [User.current.id]
    session[:meeting_contact_ids] = []
    session[:meeting_watcher_ids] = []
    nested_objects_from_session
  end

  def copy
    (render_403; return false) unless can_create_agenda?
    i = -1
    @old_object = model_class.find(params[:id])
    @object = model_class.new(@old_object.attributes)
    @object.meeting_questions_attributes = @old_object.meeting_questions.map(&:attributes).inject({}){ |result, item|
      result.update((i+=1) => item.delete_if{|key, value| %w{updated_on created_on meeting_agenda_id id}.include?(key) } )
    }
    session[:meeting_member_ids] = (@old_object.user_ids + [User.current.id]).uniq
    session[:meeting_contact_ids] = @old_object.contact_ids
    session[:meeting_watcher_ids] = @old_object.watcher_ids
    nested_objects_from_session
    render action: 'new'
  end

  def from_protocol
    (render_403; return false) unless can_create_agenda?
    i = -1
    @old_object = MeetingProtocol.find(params[:meeting_protocol_id])
    @object = MeetingAgenda.new(@old_object.meeting_agenda.attributes.merge(@old_object.attributes))
    @object.meeting_questions_attributes = @old_object.all_meeting_answers.inject({}){ |result, item|
      result.update((i+=1) => {title: item.meeting_question.to_s, description: item.description, issue_id: item.issue_id, user_id: item.reporter_id, contact_id: item.external_reporter_id, user_id_is_contact: item.reporter_id_is_contact})
    }
    session[:meeting_member_ids] = (@old_object.meeting_agenda.user_ids + [User.current.id]).uniq
    session[:meeting_contact_ids] = @old_object.meeting_agenda.contact_ids
    session[:meeting_watcher_ids] = @old_object.meeting_agenda.watcher_ids
    nested_objects_from_session
    render action: 'new'
  end


  def create
    (render_403; return false) unless can_create_agenda?
    @object.meeting_members_attributes = session[:meeting_member_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_member_ids].present?
    @object.meeting_contacts_attributes = session[:meeting_contact_ids].map{ |contact_id| {contact_id: contact_id} } if session[:meeting_contact_ids].present?
    @object.meeting_watchers_attributes = session[:meeting_watcher_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_watcher_ids].present?
    @object.save_attachments(params[:attachments])
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
    (render_403; return false) unless can_update_agenda?(@object)
    nested_objects_from_database
  end

  def update
    (render_403; return false) unless can_update_agenda?(@object)
    @object.save_attachments(params[:attachments])
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
    (render_403; return false) unless can_destroy_agenda?(@object)
    close_invites
    if @object.update_attribute(:is_deleted, true)
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to action: 'index'
  end

  def assert
    (render_403; return false) unless can_assert?(@object)
    @object.update_attribute(:asserted, true)
  end

  def send_asserter_invite
    (render_403; return false) unless can_asserter_invite?(@object)
    flash[:notice] = l(:notice_asserter_invite_sent)
    Mailer.meeting_asserter_invite(@object).deliver
    redirect_to action: 'show', id: @object.id
  end

  def restore
    (render_403; return false) unless can_restore_agenda?(@object)
    flash[:notice] = l(:notice_meeting_agenda_successful_restored)
    @object.update_attribute(:is_deleted, false)
    redirect_to action: 'show', id: @object.id
  end

private
  def close_invites
    issues = @object.invites
    issues.each do |invite|
      cancel_issue(invite)
    end
  end

  def cancel_issue(issue)
    issue.init_journal(User.current, ::I18n.t(:message_meeting_canceled))
    issue.status = IssueStatus.find(Setting.plugin_redmine_meeting[:cancel_issue_status])
    issue.save!
  end

  def nested_objects_from_session
    @users = User.active.sorted.where(id: session[:meeting_member_ids])
    @contacts = Contact.order_by_name.where(id: session[:meeting_contact_ids])
    @watchers = User.active.sorted.where(id: session[:meeting_watcher_ids])
    @external_approvers = Contact.order_by_name.where(id: session[:meeting_external_approvers_ids])
  end

  def nested_objects_from_database
    @users = @object.users
    @contacts = @object.contacts
    @watchers = @object.watchers
    @external_approvers = @object.external_approvers
  end

  def model_class
    MeetingAgenda
  end

  def model_sym
    :meeting_agenda
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
