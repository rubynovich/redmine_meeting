class MeetingWatchersController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create, :destroy, :autocomplete_for_user]
  before_filter :require_meeting_manager

  def new
    @no_watchers = User.active.sorted
    @watchers = if @object.id.present?
      @object.watchers
    else
      users_from_session
    end
    @no_watchers -= @watchers
  end

  def create
    new_watchers_ids = (params[:meeting_container].present? ? params[:meeting_container][:user_ids] : [])
    new_watchers = new_watchers_ids.map{ |user_id| MeetingWatcher.new(user_id: user_id) }.compact

    @watchers = if @object.id.present?
      @object.meeting_watchers << new_watchers
      @object.save
      @object.watchers
    else
      session[session_id] = (new_watchers + session[session_id]).uniq
      users_from_session
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @watchers = if @object.id.present?
      user = User.find(params[:id])
      MeetingWatcher.where(meeting_container_type: @object.class, meeting_container_id: @object.id, user_id: user.id).try(:destroy_all)
      @object.watchers
    else
      session[session_id] -= [ params[:id] ]
      users_from_session
    end

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @no_watchers = User.active.sorted.like(params[:q])
    @no_watchers -= if @object.id.present?
      @object.watchers
    else
      users_from_session
    end

    render layout: false
  end

private

  def find_object
    @object = case params[:meeting_container_type]
      when 'MeetingAgenda'
        MeetingAgenda.find(params[:meeting_container_id]) rescue MeetingAgenda.new
      when 'MeetingProtocol'
        MeetingProtocol.find(params[:meeting_container_id]) rescue MeetingProtocol.new
    end
  end

  def session_id
    :meeting_watcher_ids
  end

  def users_from_session
    User.active.sorted.find(session[session_id])
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
