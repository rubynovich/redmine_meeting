class MeetingApprover < ActiveRecord::Base
  unloadable

  validates_presence_of :meeting_container_id, :meeting_container_type, :user_id
  validates_presence_of :approved_on, if: -> { self.approved? }
  validates_uniqueness_of :user_id,  scope: [:meeting_container_id, :meeting_container_type]

  belongs_to :user
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_validation :add_approved_on, if: -> { self.approved? && !self.class.find(self.id).approved? }
  before_create :add_author_id

  scope :open, ->(status = true) {
    where("#{self.table_name}.deleted = ?", !status)
  }

private
  def add_approved_on
    self.approved_on = Time.now
  end

  def add_author_id
    self.author = User.current
  end
end
