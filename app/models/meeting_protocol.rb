class MeetingProtocol < ActiveRecord::Base
  unloadable

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :meeting_agenda
  has_many :meeting_answers, dependent: :delete_all
  has_many :meeting_participators, dependent: :delete_all
  has_many :users, through: :meeting_participators
  has_many :meeting_members, through: :meeting_agenda

  accepts_nested_attributes_for :meeting_answers, allow_destroy: true
  accepts_nested_attributes_for :meeting_participators, allow_destroy: true

  attr_accessible :meeting_answers_attributes
  attr_accessible :meeting_participators_attributes
  attr_accessible :meeting_agenda_id

  before_create :add_author_id

  validates_uniqueness_of :meeting_agenda_id

private

  def add_author_id
    self.author_id = User.current.id
  end
end
