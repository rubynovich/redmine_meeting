class MeetingContact < ActiveRecord::Base
  unloadable
  belongs_to :contact
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_create :add_author_id

  validates_presence_of :contact_id
  validates_uniqueness_of :contact_id,  scope: [:meeting_container_id, :meeting_container_type]


  def send_notice
    self.sidekiq_delay.send_notice_async
  end

  def send_notice_async
    Mailer.meeting_contacts_notice(self).deliver
  end

  def send_invite
    self.sidekiq_delay.send_invite_aync
  end

  def send_invite_aync
    begin
      Mailer.meeting_contacts_invite(self).deliver
    rescue
      nil
    end
  end

private

  def add_author_id
    self.author_id = User.current.id
  end
end
