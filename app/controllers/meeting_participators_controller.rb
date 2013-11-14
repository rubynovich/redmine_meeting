class MeetingParticipatorsController < ApplicationController
  unloadable

  before_filter :find_object, :only => [:new, :create, :destroy, :autocomplete_for_user]
  before_filter :require_meeting_manager

  def new
    @no_members = User.active.order(:lastname, :firstname)
    @members = []
    if @object.present?
      @members = @object.users
    else
      @members = User.where(id: session[session_sym])
    end
    @no_members -= @members
  end

  def create
    new_members = (params[model_sym].present? ? params[model_sym][:user_ids] : [])

    @members = if @object.present?
      @object.meeting_participators << new_members.map{ |user_id| MeetingParticipator.new(user_id: user_id) }.compact
      @object.save
      @object.users
    else
      session[session_sym] = (new_members + session[session_sym]).map(&:to_i).uniq
      User.sorted.find(session[session_sym])
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @members = if @object.present?
      MeetingParticipator.where(model_sym_id => @object.id, user_id: params[:id]).try(:destroy_all)
      @object.users
    else
      session[session_sym] -= [params[:id].to_i]
      User.sorted.find(session[session_sym])
    end

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @members = if @object.present?
      @object.users
    else
      User.sorted.find(session[session_sym])
    end

    @no_members = User.active.like(params[:q]).sorted - @members

    render :layout => false
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
