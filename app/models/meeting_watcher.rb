class MeetingWatcher < ActiveRecord::Base
  unloadable
  belongs_to :watcher, foreign_key: 'user_id', class_name: 'User'
#  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

#  before_create :add_author_id

  after_create :send_mail_you_are_meeting_watcher
  before_destroy :send_mail_you_are_not_meeting_watcher

  validates_presence_of :user_id
  validates_uniqueness_of :user_id,  scope: [:meeting_container_id, :meeting_container_type]

  def send_mail_you_are_meeting_watcher
    Rails.logger.error("callback".red)
    Mailer.mail_you_are_meeting_watcher(self.watcher, self.meeting_container).deliver
  end

  def send_mail_you_are_not_meeting_watcher
    Mailer.mail_you_are_not_meeting_watcher(self.watcher, self.meeting_container).deliver
  end

#private

#  def add_author_id
#    self.author_id = User.current.id
#  end
end
