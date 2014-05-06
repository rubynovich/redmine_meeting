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
    Rails.logger.debug(" in Participator create".red)
    if @object.present?
      Rails.logger.debug("object present, work with db".red)
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
      Rails.logger.debug("there is no object working with session".red)
      session[session_sym] = session[session_sym].merge( Hash[ user_ids.map{|user_id| [user_id.to_i, true] }])
      Rails.logger.debug("hash in session after modificatipon".red + session[session_sym].inspect)
      @members = present_participators_from_session
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    target_id = params[:id].to_i

    @members = if @object.present?
                 Rails.logger.debug('Participator destroy from database'.red)
                 target = MeetingParticipator.where(model_sym_id => @object.id, user_id: target_id)
                 if @object.meeting_agenda.user_ids.include?(target_id)
                   Rails.logger.debug('Agenda member -  setting attended to false'.red)
                   target.update_attribute(:attended, false)
                 else
                   Rails.logger.debug('Agenda member - destroy completly'.red)
                   Rails.logger.debug('Target '.red + target.inspect)
                   target.destroy

                 end
                 @object.users
               else
                 Rails.logger.debug('Participator destroy from session.'.red)
                 Rails.logger.debug('Before: '.red + session[session_sym].inspect)

                 if session[:permanent_participators_ids].include?(target_id)
                   session[session_sym][target_id] = false
                 else
                   session[session_sym].delete(target_id)
                 end

                 Rails.logger.debug('After: '.red + session[session_sym].inspect)
                 present_participators_from_session
               end
    
    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @members = if @object.present?
                 @object.meeting_participators.where(attended: true).map(&:user)
               else
                 present_participators_from_session
               end

    @no_members = User.active.like(params[:q]).sorted - @members

    render :layout => false
  end

  def accept
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

  def present_participators_from_session
    User.sorted.find(session[session_sym].select{|k,v| v}.keys)
  end

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
