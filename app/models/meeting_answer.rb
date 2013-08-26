class MeetingAnswer < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :meeting_question
  belongs_to :user
  belongs_to :reporter, class_name: "User", foreign_key: "reporter_id"
  belongs_to :issue
  has_one :status, through: :issue
  has_one :project, through: :issue

  validates_presence_of :user_id, :description, :start_date, :due_date, :meeting_question_id
end
