class MeetingExternalApproversController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create, :destroy, :autocomplete_for_contact]
  before_filter :require_meeting_manager

  def new
    @no_contacts = Contact.order_by_name.people
    @external_approvers = if @object.id.present?
      @object.external_approvers
    else
      contacts_from_session
    end
    @no_contacts -= @external_approvers
  end

  def create
    new_contacts = (params[:meeting_container].present? ? params[:meeting_container][:contact_ids] : [])

    @external_approvers = if @object.id.present?
      @object.meeting_external_approvers << new_contacts.map{ |contact_id| MeetingExternalApprover.new(contact_id: contact_id) }.compact
      @object.save
      @object.external_approvers
    else
      session[session_id] = (new_contacts + session[session_id]).map(&:to_i).uniq
      contacts_from_session
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @external_approvers = if @object.id.present?
      contact = Contact.find(params[:id])
      MeetingExternalApprover.where(meeting_container_type: @object.class, meeting_container_id: @object.id, contact_id: contact.id).try(:destroy_all)
      @object.external_approvers
    else
      session[session_id] -= [ params[:id].to_i ]
      contacts_from_session
    end

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_contact
    @no_contacts = Contact.order_by_name.people.by_name(params[:q])
    @no_contacts -= if @object.id.present?
      @object.external_approvers
    else
      contacts_from_session
    end

    render :layout => false
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
    :meeting_external_approvers_ids
  end

  def contacts_from_session
    Contact.order_by_name.people.find(session[session_id])
  end

  def require_meeting_manager
    (render_403; return false) unless User.current.meeting_manager?
  end
end
