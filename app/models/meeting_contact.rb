class MeetingContact < ActiveRecord::Base
  unloadable
  belongs_to :contact
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_create :add_author_id

  validates_presence_of :contact_id
  validates_uniqueness_of :contact_id,  scope: [:meeting_container_id, :meeting_container_type]

  def send_email(participation_form)
    case self.meeting_container_type
    when 'MeetingAgenda'
      send_email_from_agenda(participation_form)
    when 'MeetingProtocol'
    end
  end

  def send_fax(participation_form)
    case self.meeting_container_type
    when 'MeetingAgenda'
      send_fax_from_agenda(participation_form)
    when 'MeetingProtocol'
    end
  end

  def send_sms(participation_form)
    case self.meeting_container_type
    when 'MeetingAgenda'
      send_sms_from_agenda(participation_form)
    when 'MeetingProtocol'
    end
  end

private

  def add_author_id
    self.author = User.current
  end

  def send_email_from_agenda(participation_form)
    Mailer.meeting_contacts_registered_invite(self, participation_form).deliver
  end

  def send_fax_from_agenda(participation_form)
    settings = Setting.plugin_redmine_meeting
    keywords = {
      contact: self.contact,
      "contact.company" => self.contact.company,
      fax: self.fax
    }
    Issue.create(
      tracker_id: settings[:fax_tracker_id],
      project_id: settings[:fax_project_id],
      subject: apply_keywords(settings[:fax_subject]),
      description: apply_keywords(settings[:fax_description]),
      assigned_to_id: settings[:fax_assigned_to_id],
      start_date: Date.today,
      due_date: Date.today
    )
  end

  def apply_keywords(str, keywords)
    keywords.inject(str){ |result, keywords|
      result.gsub("%#{keywords.first}%", "#{keywords.last}")
    }
  end

  def send_sms_from_agenda(participation_form)
  end
end
