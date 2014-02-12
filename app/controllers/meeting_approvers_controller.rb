class MeetingApproversController < ApplicationController
  unloadable

  helper :watchers
  before_filter :require_meeting_manager

  def new
    @show_form = "true"
    @users = User.active.order([:lastname, :firstname]).all(limit: 100)
    @users -= opened_meeting_approver_users
  end

  def create
    if params[:meeting_approver].present? && params[:meeting_approver][:user_ids].present?
      User.find(params[:meeting_approver][:user_ids]).each do |user|
        data = {user_id: user.id, meeting_container_type: params[:meeting_container_type], meeting_container_id: params[:meeting_container_id]}
        if MeetingApprover.where(data.merge({deleted: true})).present?
          MeetingApprover.where(data.merge({deleted: true})).first.update_attributes(deleted: false)
        else
          MeetingApprover.create(data)
        end
      end
    end

    @users = meeting_approver_users

    respond_to do |format|
      format.js
    end
  end

  def update
    item = MeetingApprover.find(params[:id])
    item.update_attributes(params[:meeting_approver])

    @users = meeting_approver_users
  end

  def destroy
    if item = MeetingApprover.find(params[:id])
      item.update_attributes(deleted: true)
    end

    @users = meeting_approver_users

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).all(limit: 100)
    @users -= meeting_approvers.open.map(&:user)

    render layout: false
  end

  def card
    @collection = meeting_approvers
  end

private
  def meeting_approvers
    MeetingApprover.where(meeting_container_type: params[:meeting_container_type], meeting_container_id: params[:meeting_container_id])
  end

  def opened_meeting_approver_users
    meeting_approvers.open.map(&:user)
  end

  def meeting_approver_users
    meeting_approvers.map(&:user)
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
