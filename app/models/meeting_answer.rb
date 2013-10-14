class MeetingAnswer < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :meeting_question
  belongs_to :user
  belongs_to :reporter, class_name: "User", foreign_key: "reporter_id"
  belongs_to :issue
  belongs_to :question_issue, class_name: "Issue", foreign_key: "question_issue_id"
  has_one :status, through: :issue
  has_one :project, through: :issue
  has_one :meeting_agenda, through: :meeting_protocol
  has_one :author, through: :meeting_protocol
  has_many :meeting_answers, through: :meeting_protocol, uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true
  has_many :users, through: :meeting_protocol, uniq: true

  validates_presence_of :user_id, :description, :start_date, :due_date, :meeting_question_id

#  def reporter
#    if super.present?
#      super
#    elsif self.meeting_question.present? && self.meeting_question.user.present?
#      self.meeting_question.user
#    end
#  end

  def question_issue
    super.present? ? super : meeting_question.try(:issue)
  end

  def to_s
    self.description
  end
end
