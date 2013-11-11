class MeetingExtraAnswer < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :user
  belongs_to :reporter, class_name: "User", foreign_key: "reporter_id"
  belongs_to :question_issue, class_name: "Issue", foreign_key: "question_issue_id"
  belongs_to :issue
  has_one :pending_issue, class_name: "MeetingPendingIssue", as: :meeting_container
  has_one :status, through: :issue
  has_one :project, through: :issue
  has_one :meeting_agenda, through: :meeting_protocol
  has_one :author, through: :meeting_protocol
  has_many :meeting_answers, through: :meeting_protocol, uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true
  has_many :users, through: :meeting_protocol, uniq: true

  validates_presence_of :reporter_id, :user_id, :description, :start_date, :due_date, :meeting_question_name
  validates :start_date, date: true
  validates :due_date, date: true
  validate :validate_due_date

  def meeting_question
    self.meeting_question_name
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
    if self.due_date && (self.due_date < Date.today)
      errors.add :due_date, :greated_then_now
    end
    if self.due_date && self.start_date && (self.due_date < self.start_date)
      errors.add :due_date, :greater_than_start_date
    end
  end
end
