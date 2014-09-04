class MeetingComment < ActiveRecord::Base
  unloadable

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
#  belongs_to :meeting_answer
  belongs_to :meeting_container, polymorphic: true

  validates_presence_of :note, :meeting_container_id, :meeting_container_type

  before_save :add_author_id
  after_create :message_meeting_comment_create

private
  def message_meeting_comment_create
    Mailer.meeting_comment_create(self).deliver
  end

  def add_author_id
    self.author_id = User.current.id
  end
end
