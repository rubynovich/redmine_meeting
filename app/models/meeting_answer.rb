class MeetingAnswer < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :parent, class_name: "MeetingProtocol", foreign_key: "meeting_protocol_id"
  belongs_to :meeting_question
  belongs_to :user, class_name: "Person", foreign_key: "user_id"
  belongs_to :external_user, class_name: "Contact", foreign_key: "external_user_id"
  belongs_to :reporter, class_name: "Person", foreign_key: "reporter_id"
  belongs_to :external_reporter, class_name: "Contact", foreign_key: "external_reporter_id"
  belongs_to :question_issue, class_name: "Issue", foreign_key: "question_issue_id"
  belongs_to :issue
  has_one :pending_issue, class_name: "MeetingPendingIssue", as: :meeting_container
  has_one :status, through: :issue
#  has_one :project, through: :issue
  has_one :meeting_agenda, through: :meeting_protocol
  has_one :author, through: :meeting_protocol
  has_many :meeting_answers, through: :meeting_protocol, uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true
  has_many :users, through: :meeting_protocol, uniq: true

  validates_presence_of :description, :start_date, :due_date, :meeting_question_id
  validates_presence_of :reporter_id, unless: -> { self.reporter_id_is_contact? }
  validates_presence_of :external_reporter_id, if: -> { self.reporter_id_is_contact? }
  validates_presence_of :external_user_id, if: -> { self.user_id_is_contact? }
  validates_presence_of :user_id, unless: -> { self.user_id_is_contact? }
  validates :start_date, date: true
  validates :due_date, date: true
  validate :validate_due_date

#  def reporter
#    if super.present?
#      super
#    elsif self.meeting_question.present? && self.meeting_question.user.present?
#      self.meeting_question.user
#    end
#  end

  def project
    if self.question_issue.present?
      self.question_issue.project
    elsif self.meeting_question.present?
      self.meeting_question.project
    elsif self.issue.present?
      self.issue.project
    end
  end

  def question_issue
    super.present? ? super : meeting_question.try(:issue)
  end

  def to_s
    self.description
  end

  def issue
    if super
      super
    elsif self.pending_issue
      self.pending_issue
    end
  end

private

  def validate_due_date
#    if self.due_date && (self.due_date < Date.today)
#      errors.add :due_date, :greated_then_now
#    end
    if self.due_date && self.start_date && (self.due_date < self.start_date)
      errors.add :due_date, :greater_than_start_date
    end
  end
end
