class MeetingMembersController < ApplicationController
  unloadable
  before_filter :find_object, :only => [:new, :create, :destroy, :autocomplete_for_user]

  def new
    @users = User.active.order(:lastname, :firstname)
    if @object.present?
      @users -= @object.meeting_members.map(&:user)
    else
      @users -= User.where(id: session[:meeting_member_ids])
    end
  end

  def create
    members = params[model_sym][:user_ids] if params[model_sym].present?

    @users = if @object.present?
      @object.meeting_members << members.map{ |user_id| MeetingMember.new(user_id: user_id) }.compact
      #TODO save?
      @object.meeting_members.map(&:user_id)
    else
      session[:meeting_member_ids] = (members + session[:meeting_member_ids]).uniq
      User.find(session[:meeting_member_ids])
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @users = if @object.present?
      MeetingMember.where(model_sym_id => @object.id, user_id: params[:user_id]).try(:destroy_all)
      model_class.meeting_members.map(&:user_id)
    else
      session[:meeting_member_ids] -= params[:user_id]
      User.find(session[:meeting_member_ids])
    end


    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).order(:lastname, :firstname)
    @users -= if @object.present?
      @object.meeting_members.map(&:user)
    else
      User.find(session[:meeting_member_ids])
    end

    render :layout => false
  end

private

  def find_object
    @object = model_class.find(params[:model_sym_id])
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
#    def find_issue
#      @issue = Issue.find(params[:issue_id])
#      @project = @issue.project
#    rescue ActiveRecord::RecordNotFound
#      render_404
#    end
end
