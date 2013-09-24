class MeetingContact < ActiveRecord::Base
  unloadable
  belongs_to :contact
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_create :add_author_id

  validates_presence_of :meeting_container_id, :meeting_container_type, :contact_id
  validates_uniqueness_of :contact_id,  scope: [:meeting_container_id, :meeting_container_type]

private

  def add_author_id
    self.author = User.current
  end
end
