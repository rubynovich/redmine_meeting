class MeetingAnswer < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :meeting_question
  belongs_to :user
  belongs_to :issue
  has_one :status, through: :issue
  has_one :project, through: :issue
end
