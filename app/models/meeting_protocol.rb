class MeetingProtocol < ActiveRecord::Base
  unloadable

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :meeting_agenda
  has_many :meeting_answers, dependent: :delete_all, order: [:meeting_question_id]
  has_many :meeting_participators, dependent: :delete_all
  has_many :users, through: :meeting_participators, order: [:lastname, :firstname]
  has_many :meeting_members, through: :meeting_agenda

  accepts_nested_attributes_for :meeting_answers, allow_destroy: true
  accepts_nested_attributes_for :meeting_participators, allow_destroy: true

  attr_accessible :meeting_answers_attributes
  attr_accessible :meeting_participators_attributes
  attr_accessible :meeting_agenda_id

  before_create :add_author_id

  validates_uniqueness_of :meeting_agenda_id
  validates_presence_of :meeting_agenda_id
  validate :presence_of_meeting_answers, if: -> {self.meeting_answers.blank?}
  validate :presence_of_meeting_participators, if: -> {self.meeting_participators.blank?}

private

  def presence_of_meeting_answers
    errors.add(:meeting_answers, :must_exist)
  end

  def presence_of_meeting_participators
    errors.add(:meeting_participators, :must_exist)
  end

  def add_author_id
    self.author_id = User.current.id
  end
end
