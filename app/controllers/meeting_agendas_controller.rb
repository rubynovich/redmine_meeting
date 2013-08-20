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

  def new
    @users = []
    session[:meeting_member_ids] = []
  end

  def edit
    @users = @object.meeting_members.map(&:user)
  end

  def index
    @collection = model_class.order('created_on desc')
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
