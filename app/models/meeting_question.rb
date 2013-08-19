class MeetingQuestion < ActiveRecord::Base
  unloadable
  belongs_to :issue
  belongs_to :user
  belongs_to :meeting_agenda
  has_one :status, through: :issue
  has_one :project, through: :issue
  has_one :meeting_answer
  has_many :meeting_questions, through: :meeting_agenda
  has_many :meeting_members, through: :meeting_agenda
  has_many :users, through: :meeting_agenda


  after_save :add_new_users_from_questions

  def to_s
    self.title
  end

private

  def add_new_users_from_questions
    (self.meeting_questions.map(&:user) - self.users).each do |user|
      MeetingMember.create(user: user, meeting_agenda: self.meeting_agenda)
    end
  end

end
