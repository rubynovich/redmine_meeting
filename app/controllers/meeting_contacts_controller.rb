class MeetingContactsController < ApplicationController
  unloadable

  before_filter :find_object, only: [:new, :create, :destroy, :autocomplete_for_user]

  def new
    @no_contacts = Contact.order_by_name.people
    @contacts = if @object.id.present?
      @object.contacts
    else
      Contact.where(id: session[:meeting_contact_ids])
    end
    @no_contacts -= @contacts
  end

  def create
    new_contacts = (params[:meeting_container].present? ? params[:meeting_container][:contact_ids] : [])

    @contacts = if @object.id.present?
      @object.meeting_contacts << new_contacts.map{ |contact_id| MeetingContact.new(contact_id: contact_id) }.compact
      @object.save
      @object.contacts
    else
      session[:meeting_contact_ids] = (new_contacts + session[:meeting_contact_ids]).uniq
      Contact.order_by_name.find(session[:meeting_contact_ids])
    end

    respond_to do |format|
      format.js
    end
  end

  def destroy
    @contacts = if @object.id.present?
      contact = Contact.find(params[:id])
      MeetingContact.where(meeting_container_type: @object.class, meeting_container_id: @object.id, contact_id: contact.id).try(:destroy_all)
      @object.contacts.inspect
    else
      session[:meeting_contact_ids] -= [ params[:id] ]
      Contact.order_by_name.find(session[:meeting_contact_ids])
    end

    respond_to do |format|
      format.js
    end
  end

  def autocomplete_for_contact
    @no_contacts = Contact.order_by_name.people.by_name(params[:q])
    @no_contacts -= if @object.present?
      @object.contacts
    else
      Contact.order_by_name.people.find(session[:meeting_contact_ids])
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

end
