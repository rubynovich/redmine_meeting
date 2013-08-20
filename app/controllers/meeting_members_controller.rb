class MeetingMembersController < ApplicationController
  unloadable
  before_filter :find_object, :only => [:new, :create, :destroy, :autocomplete_for_user]

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
      User.find(session[:meeting_member_ids]).order(:lastname, :firstname)
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @users = if @object.present?
      MeetingMember.where(model_sym_id => @object.id, user_id: params[:id]).try(:destroy_all)
      @object.users
    else
      session[:meeting_member_ids] -= [ params[:id].to_i ]
      User.find(session[:meeting_member_ids]).order(:lastname, :firstname)
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
      User.find(session[:meeting_member_ids]).order(:lastname, :firstname)
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
end
