class MeetingQuestion < ActiveRecord::Base
  unloadable
  belongs_to :issue
  belongs_to :user
  belongs_to :meeting_agenda
  has_one :status, through: :issue
  has_one :project, through: :issue
  has_one :meeting_answer
  has_many :meeting_questions, through: :meeting_agenda, uniq: true
  has_many :meeting_members, through: :meeting_agenda, uniq: true
  has_many :users, through: :meeting_agenda, uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true

  after_save :add_new_users_from_questions

  validates_presence_of :title
  validates_uniqueness_of :title, scope: :meeting_agenda_id

  def to_s
    self.title
  end

private

  def add_new_users_from_questions
    (self.meeting_questions.map(&:user) - self.users).each do |user|
      MeetingMember.create(user_id: user.id, meeting_agenda_id: self.meeting_agenda_id)
    end
  end

end
