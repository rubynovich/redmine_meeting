class MeetingAgendasController < ApplicationController
  unloadable

  before_filter :find_object, only: [:edit, :show, :destroy, :update, :send_invites, :resend_invites]
  before_filter :new_object, only: [:new, :create]

  helper :meeting_agendas
  include MeetingAgendasHelper
  helper :meeting_comments
  include MeetingCommentsHelper
  helper :meeting_approvers
  include MeetingApproversHelper
  include ApplicationHelper

  def show
    (render_403; return false) unless can_show_agenda?(@object)
  end

  def send_invites
    (render_403; return false) unless can_send_invites?(@object)
    @object.meeting_members.reject(&:issue).each do |member|
      member.send_invite(url_for(controller: 'meeting_agendas', action: 'show', id: @object.id))
    end

    redirect_to controller: 'meeting_agendas', action: 'show', id: @object.id
  end

  def resend_invites
    (render_403; return false) unless can_send_invites?(@object)
    @object.meeting_members.each do |member|
      member.resend_invite(url_for(controller: 'meeting_agendas', action: 'show', id: @object.id))
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

    begin
      places = MeetingRoom.open.
        where("LOWER(name) LIKE LOWER(?)", "%#{q}%").
        map{ |r| {'label' => r.name, 'value' => r.name} } +
        places
    rescue
    end

    render :text => places.to_json, :layout => false
  end

  def index
    @limit = per_page_option

    @scope = model_class.
      time_period(params[:time_period_created_on], 'meeting_agendas.created_on').
      time_period(params[:time_period_meet_on], 'meeting_agendas.meet_on').
      eql_field(params[:author_id], 'meeting_agendas.author_id').
      eql_field(params[:created_on], 'DATE(meeting_agendas.created_on)').
      eql_field(params[:meet_on], 'meeting_agendas.meet_on').
      like_field(params[:subject], 'meeting_agendas.subject').
      eql_project_id(params[:project_id]).
      uniq

    @scope = @scope.joins(:meeting_members).includes(:meeting_approvers).
      where("meeting_members.user_id = :user_id OR meeting_agendas.author_id = :user_id OR meeting_approvers.user_id = :user_id", user_id: User.current.id) unless admin?

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
    @object.priority = IssuePriority.default
    session[:meeting_member_ids] = [User.current.id]
    session[:meeting_contact_ids] = []
    session[:meeting_watcher_ids] = []
    nested_objects_from_session
  end

  def create
    @object.meeting_members_attributes = session[:meeting_member_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_member_ids].present?
    @object.meeting_contacts_attributes = session[:meeting_contact_ids].map{ |contact_id| {contact_id: contact_id} } if session[:meeting_contact_ids].present?
    @object.meeting_watchers_attributes = session[:meeting_watcher_ids].map{ |user_id| {user_id: user_id} } if session[:meeting_watcher_ids].present?
    if @object.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'show', id: @object.id
    else
      nested_objects_from_session
      render action: 'new'
    end
  end

  def edit
    nested_objects_from_database
  end

  def update
    if @object.update_attributes(params[model_sym])
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @object.id
    else
      nested_objects_from_database
      render action: 'edit'
    end
  end

  def destroy
    close_invites
    flash[:notice] = l(:notice_successful_delete) if @object.destroy
    redirect_to action: 'index'
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
    issue.status = IssueStatus.find(Setting[:plugin_redmine_meeting][:cancel_issue_status])
    issue.save!
  end

  def nested_objects_from_session
    @users = User.active.sorted.find(session[:meeting_member_ids])
    @contacts = Contact.order_by_name.find(session[:meeting_contact_ids])
    @watchers = User.active.sorted.find(session[:meeting_watcher_ids])
  end

  def nested_objects_from_database
    @users = @object.users
    @contacts = @object.contacts
    @watchers = @object.watchers
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
end
