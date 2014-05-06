# -*- coding: utf-8 -*-
class MeetingParticipatorsController < ApplicationController
  unloadable

  before_filter :find_object, :only => [:new, :create, :destroy, :autocomplete_for_user]
  before_filter :require_meeting_manager

  include MeetingParticipatorsHelper

  def new
    @no_members = User.active.order(:lastname, :firstname)
    @members = if @object.present?
                 @object.meeting_participators.where(attended: true).map(&:user)
               else
                 User.find(session[session_sym].class == Hash ? session[session_sym].keys : session[session_sym]) # FIXME в session_sym где-то кладется массив вместо хеша
               end
    @no_members -= @members
  end

  def create
    user_ids = (params[model_sym].present? ? params[model_sym][:user_ids] : [])
    Rails.logger.error(" in Participator create".red)
    if @object.present?
      Rails.logger.error("object present, work with db".red)
      user_ids.each do |user_id|
        turned_off_user = MeetingParticipator.where(user_id: user_id, meeting_protocol_id: params[:meeting_protocol_id], attended: false).first
        if turned_off_user
          turned_off_user.update_attribute(:attended, true)
        else 
          MeetingParticipator.create!(user_id: user_id, meeting_protocol_id: params[:meeting_protocol_id], attended: true)
        end
      end
      @members = @object.users
    else
      Rails.logger.error("there is no object working with session".red)
      session[session_sym] = session[session_sym].merge( Hash[ user_ids.map{|user_id| [user_id.to_i, true] }])
      Rails.logger.error("hash in session after modificatipon".red + session[session_sym].inspect)
      @members = User.sorted.find(session[session_sym].select{|k,v| v}.keys)
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy

    @members = if @object.present?
                 # MeetingParticipator.where(model_sym_id => @object.id, user_id: params[:id]).try(:destroy_all)
                 MeetingParticipator.where(model_sym_id => @object.id, user_id: params[:id]).each{|par| par.update_attribute(:attended, false) }
                 @object.users
               else
                 Rails.logger.error('Participator destroy from session.'.red)
                 Rails.logger.error('Before: '.red + session[session_sym].inspect)

                 if session[:permanent_participators_ids].include?(params[:id].to_i)
                   session[session_sym][params[:id].to_i] = false
                 else
                   session[session_sym].delete(params[:id].to_i)
                 end

                 Rails.logger.error('After: '.red + session[session_sym].inspect)
                 User.sorted.find(session[session_sym].select{|k,v| v}.keys)
               end
    
    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @members = if @object.present?
                 @object.meeting_participators.where(attended: true).map(&:user)
               else
                 User.sorted.find(session[session_sym].select{|k,v| v}.keys)
               end

    @no_members = User.active.like(params[:q]).sorted - @members

    render :layout => false
  end

  def accept
#    @member = MeetingParticipator.find(params[:id])
#    (render_403; return false) unless can_accept?(@member)
#    solved_status_id = Setting.plugin_redmine_meeting[:solved_issue_status]
#    issue = @member.issue
#    issue.status_id = solved_status_id
#    if issue.save
#      flash[:notice] = l(:notice_successful_notice_accept)
#    else
#      flash[:error] = l(:error_notice_accept_failed)
#    end
    @object = MeetingParticipator.find(params[:id])
    if @object.present? && @object.sended_notice_on.present? && @object.saw_protocol_on.blank?
      @object.saw_protocol_on = Time.now
      if @object.save
        flash[:notice] = l(:notice_successful_notice_accept)
      else
        flash[:error] = l(:error_invite_accept_failed)
      end
    end
  end

private

  def find_object
    @object = model_class.find(params[model_sym_id]) rescue nil
  end

  def model_class
    MeetingProtocol
  end

  def model_sym
    :meeting_protocol
  end

  def model_sym_id
    :meeting_protocol_id
  end

  def session_sym
    :meeting_participator_ids
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
