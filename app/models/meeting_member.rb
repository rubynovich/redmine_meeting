class MeetingMember < ActiveRecord::Base
  unloadable

  belongs_to :meeting_agenda
  belongs_to :user
  belongs_to :issue
  has_one :status, through: :issue
  has_one :meeting_participator
  has_many :meeting_questions, through: :meeting_agenda, uniq: true

  validates_uniqueness_of :user_id, scope: :meeting_agenda_id
  validates_presence_of :user_id
  validate :validate_meeting_agenda, if: -> {self.meeting_agenda.present? && !self.meeting_agenda.valid?}

  def to_s
    self.user.try(:name) || ''
  end

  def send_invite(url = nil)
    @url = url
    self.update_attribute(:issue_id, create_issue.try(:id))
  rescue
  end

  def resend_invite(url = nil)
    @url = url
    close_status_id = IssueStatus.find(Setting[:plugin_redmine_meeting][:issue_status]).id
    if self.issue.present? && !self.issue.closed?
      self.issue.update_attribute(:status_id, close_status_id)
      self.update_attribute(:issue_id, nil)
      self.send_invite(url)
    end
  rescue
  end

private
  #FIXME Перенести сие в контроллер Повестки

  def key_words
    {
      subject: self.meeting_agenda.subject,
      meet_on: self.meeting_agenda.meet_on.strftime("%d.%m.%Y"),
      start_time: self.meeting_agenda.start_time.strftime("%H:%M"),
      end_time: self.meeting_agenda.end_time.strftime("%H:%M"),
      author: self.meeting_agenda.author.name,
      place: self.meeting_agenda.place,
      url: @url
    }
  end

  def put_key_words(template)
    key_words.inject(template){ |result, key_word|
      result.gsub("%#{key_word[0]}%", key_word[1])
    }
  end

  def issue_subject
    put_key_words(Setting[:plugin_redmine_meeting][:subject])
  end

  def issue_description
    put_key_words(Setting[:plugin_redmine_meeting][:description])
  end

  def create_issue
    settings = Setting[:plugin_redmine_meeting]
    Issue.create!(
      status: IssueStatus.default,
      tracker: Tracker.find(settings[:issue_tracker]),
      subject: issue_subject,
      project: Project.find(settings[:project_id]),
      description: issue_description,
      author: User.current,
      start_date: Date.today,
      due_date: self.meeting_agenda.meet_on,
      priority: self.meeting_agenda.priority || IssuePriority.default,
      assigned_to: self.user)
  end

  def validate_meeting_agenda
    errors[:base] << ::I18n.t(:error_messages_meeting_agenda_not_valid)
  end
end
