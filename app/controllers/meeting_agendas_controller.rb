class MeetingAgendasController < ApplicationController
  unloadable

  before_filter :find_object, only: [:edit, :show, :destroy, :update]
  before_filter :new_object, only: [:new, :create]

  include ApplicationHelper

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

  def new
    @users = []
    session[:meeting_member_ids] = []
  end

  def edit
    @users = @object.users
  end

  def index
    @limit = per_page_option

    @scope = model_class.
      time_period(params[:time_period_created_on], :created_on).
      time_period(params[:time_period_meet_on], :meet_on).
      eql_field(params[:author_id], :author_id).
      eql_field(params[:created_on], :created_on).
      eql_field(params[:meet_on], :meet_on).
      like_field(params[:subject], :subject).
      eql_project_id(params[:project_id]).
      where(nil)

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
    if session[:meeting_member_ids].present?
      @object.meeting_members_attributes = session[:meeting_member_ids].map{ |user_id| {user_id: user_id} }
    end
    if @object.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: 'show', id: @object.id
    else
      @users = User.find(session[:meeting_member_ids])
      render action: 'new'
    end
  end

  def update
    if @object.update_attributes(params[model_sym])
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show', id: @object.id
    else
      @users = @object.users
      render action: 'edit'
    end
  end

  def destroy
    flash[:notice] = l(:notice_successful_delete) if @object.destroy
    redirect_to action: 'index'
  end

private

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
