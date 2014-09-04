class MeetingExternalApprover < ActiveRecord::Base
  unloadable
  belongs_to :contact
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_create :add_author_id
  after_create :send_mail

  validates_presence_of :contact_id
  validates_uniqueness_of :contact_id,  scope: [:meeting_container_id, :meeting_container_type]

  def to_s
    contact.to_s
  end

private

  def add_author_id
    self.author_id = User.current.id
  end

  def send_mail
    case meeting_container_type
    when 'MeetingAgenda'
      Mailer.meeting_external_approver_agenda_create(self).deliver
    when 'MeetingProtocol'
      Mailer.meeting_external_approver_protocol_create(self).deliver
    end
  end
end
