class MeetingQuestion < ActiveRecord::Base
  unloadable

  belongs_to :issue
  belongs_to :user
  belongs_to :meeting_agenda
  has_one :status, through: :issue
#  has_one :project, through: :issue
  belongs_to :project
  has_one :meeting_answer
  has_one :author, through: :meeting_agenda
  has_many :meeting_questions, through: :meeting_agenda, uniq: true
  has_many :meeting_members, through: :meeting_agenda, uniq: true
  has_many :users, through: :meeting_agenda, uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true

  acts_as_list scope: :meeting_agenda

  validates_presence_of :title, :user_id
#  validates_uniqueness_of :title, scope: :meeting_agenda_id

  def position
    0
  end

  def <=>(object)
    position <=> object.position
  end

  def to_s
    self.title
  end

  def title_with_issue
    "#{self}" + if self.issue.present?
      " (#{self.issue.tracker} ##{self.issue_id}: #{self.issue.subject})"
    else
      ""
    end
  end

  def project
    if super.present?
      super
    elsif issue.present?
      self.issue.project
    end
  end

end
