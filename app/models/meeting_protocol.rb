class MeetingProtocol < ActiveRecord::Base
  unloadable

  acts_as_attachable
  attr_accessor :project

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :meeting_agenda
  has_many :meeting_answers, dependent: :delete_all, order: [:meeting_question_id]
  has_many :issues, through: :meeting_answers, uniq: true
  has_many :meeting_participators, dependent: :delete_all
  has_many :users, through: :meeting_participators, order: [:lastname, :firstname], uniq: true
  has_many :meeting_members, through: :meeting_agenda, uniq: true

  accepts_nested_attributes_for :meeting_answers, allow_destroy: true
  accepts_nested_attributes_for :meeting_participators, allow_destroy: true

  attr_accessible :meeting_answers_attributes
  attr_accessible :meeting_participators_attributes
  attr_accessible :meeting_agenda_id

  before_create :add_author_id
  after_save :add_new_users_from_answers

  validates_uniqueness_of :meeting_agenda_id
  validates_presence_of :meeting_agenda_id
  validate :presence_of_meeting_answers, if: -> {self.meeting_answers.blank?}
  validate :presence_of_meeting_participators, if: -> {self.meeting_participators.blank?}

  scope :like_field, ->(q, field) {
    if q.present? && field.present?
      where("LOWER(#{field}) LIKE LOWER(?)", "%#{q.to_s.downcase}%")
    end
  }

  scope :eql_field, ->(q, field) {
    if q.present? && field.present?
      where("#{field} = ?", q)
    end
  }

  scope :eql_project_id, ->(q) {
    if q.present?
      joins(meeting_answers: :issue).where("issues.project_id = ?", q)
    end
  }

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    false
  end

private

  def presence_of_meeting_answers
    errors[:base] << ::I18n.t(:error_messages_meeting_answers_must_exist)
  end

  def presence_of_meeting_participators
    if self.meeting_answers.blank? || self.meeting_answers.all?{ |a| a.user.blank? }
      errors.add(:meeting_participators, :must_exist)
    end
  end

  def add_author_id
    self.author_id = User.current.id
  end

  def add_new_users_from_answers
    (self.meeting_answers.map(&:reporter) - self.users).each do |user|
      MeetingParticipator.create(user_id: user.id, meeting_protocol_id: self.id)
    end
  end
end
