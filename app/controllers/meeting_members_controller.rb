class MeetingMembersController < ApplicationController
  unloadable
  before_filter :find_object, only: [:new, :create, :destroy, :autocomplete_for_user]
  before_filter :require_meeting_manager

  def new
    @no_members = User.active.order(:lastname, :firstname)
    @users = []
    if @object.present?
      @users = @object.users
    else
      @users = User.where(id: session[:meeting_member_ids])
    end
    @no_members -= @users
  end

  def create
    members = params[model_sym][:user_ids] if params[model_sym].present?

    @users = if @object.present?
      @object.meeting_members << members.map{ |user_id| MeetingMember.new(user_id: user_id) }.compact
      @object.save
      @object.users
    else
      session[:meeting_member_ids] = (members + session[:meeting_member_ids]).uniq
      User.order(:lastname, :firstname).find(session[:meeting_member_ids])
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @users = if @object.present?
      user = User.find(params[:id])
      reporters = @object.meeting_questions.map(&:user)
      MeetingMember.where(model_sym_id => @object.id, user_id: user.id).try(:destroy_all) unless reporters.include?(user)
      @object.users
    else
      session[:meeting_member_ids] -= [ params[:id].to_i ]
      User.order(:lastname, :firstname).find(session[:meeting_member_ids])
    end

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).order(:lastname, :firstname)
    @users -= if @object.present?
      @object.users
    else
      User.order(:lastname, :firstname).find(session[:meeting_member_ids])
    end

    render :layout => false
  end

private

  def find_object
    @object = model_class.find(params[model_sym_id]) rescue nil
  end

  def model_class
    MeetingAgenda
  end

  def model_sym
    :meeting_agenda
  end

  def model_sym_id
    :meeting_agenda_id
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
