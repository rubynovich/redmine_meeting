class MeetingMembersController < ApplicationController
  unloadable
  before_filter :find_object, only: [:new, :create, :destroy,
    :autocomplete_for_user]
  before_filter :require_meeting_manager

  include MeetingMembersHelper

  def new
    @no_members = User.active.sorted
    @users = []
    if @object.present?
      @users = @object.users
    else
      @users = User.where(id: session[:meeting_member_ids])
    end
    @no_members -= @users
  end

  def create
    new_members = (params[model_sym].present? ? params[model_sym][:user_ids] : [])

    @users = if @object.present?
      new_members.each do |user_id|
        MeetingMember.create!(user_id: user_id, meeting_agenda_id: params[:meeting_agenda_id])
      end
      @object.users
    else
      session[:meeting_member_ids] = (new_members + session[:meeting_member_ids]).map(&:to_i).uniq
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
      User.sorted.find(session[:meeting_member_ids])
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
      User.sorted.find(session[:meeting_member_ids])
    end

    render :layout => false
  end

  def accept
    @member = MeetingMember.find(params[:id])
    (render_403; return false) unless can_accept?(@member)
    status_id = Setting.plugin_redmine_meeting[:solved_issue_status]
    issue = @member.issue
    issue.status_id = status_id
    if issue.save
      flash[:notice] = l(:notice_successful_invite_accept)
    else
      flash[:error] = l(:error_invite_accept_failed)
    end
  end

  def reject
    @member = MeetingMember.find(params[:id])
    (render_403; return false) unless can_accept?(@member)
    status_id = Setting.plugin_redmine_meeting[:reject_issue_status]
    issue = @member.issue
    issue.status_id = status_id
    if issue.save
      flash[:notice] = l(:notice_successful_invite_reject)
    else
      flash[:error] = l(:error_invite_reject_failed)
    end
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
