class MeetingAgenda < ActiveRecord::Base
  unloadable

  has_one :meeting_protocol
  has_many :meeting_questions, dependent: :delete_all
  has_many :issues, through: :meeting_questions
  has_many :projects, through: :issues
  has_many :statuses, through: :issues
  has_many :meeting_members, dependent: :delete_all
  has_many :users, through: :meeting_members
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'

  accepts_nested_attributes_for :meeting_questions, allow_destroy: true
  accepts_nested_attributes_for :meeting_members, allow_destroy: true

  before_create :add_author_id

  attr_accessible :meeting_members_attributes
  attr_accessible :meeting_questions_attributes
  attr_accessible :subject, :place, :meet_on, :start_time, :end_time

  scope :free, -> {
    where("id NOT IN (SELECT meeting_agenda_id FROM meeting_protocols)")
  }

  def to_s
    self.subject
  end

private

  def add_author_id
    self.author_id = User.current.id
  end
end
