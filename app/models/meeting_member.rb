class MeetingMember < ActiveRecord::Base
  unloadable

  include Rails.application.routes.url_helpers

  def self.default_url_options
    { host: Setting.host_name, protocol: Setting.protocol }
  end

  belongs_to :meeting_agenda
  belongs_to :user
#  belongs_to :person, class_name: 'Person', foreign_key: 'user_id'
  belongs_to :issue
  belongs_to :time_entry
  has_one :status, through: :issue
  has_one :meeting_participator
  has_many :meeting_questions, through: :meeting_agenda, uniq: true

  validates_uniqueness_of :user_id, scope: :meeting_agenda_id
  validates_presence_of :user_id
  validate :validate_meeting_agenda,
    if: -> {self.meeting_agenda.present? && !self.meeting_agenda.valid?}

  before_destroy :cancel_issue_for_destroyed_member,
    if: -> {self.issue.present?}

  def to_s
    self.user.try(:name) || ''
  end

  def send_invite
    self.build_issue(issue_attributes)
#    self.update_attribute(:issue_id, created_issue_id)
    if self.save
      estimated_time_create(self.issue_id)
    end
#  rescue
  end

  def resend_invite
    cancel_status_id = IssueStatus.find(Setting[:plugin_redmine_meeting][:cancel_issue_status]).id
    if self.issue.present? && !self.issue.closed?
      self.issue.update_attribute(:status_id, cancel_status_id)
      EstimatedTime.where(plan_on: self.meeting_agenda.meet_on, issue_id: self.issue_id, user_id: self.user_id).delete_all
      self.update_attribute(:issue_id, nil)
      self.send_invite
    end
#  rescue
  end

  def cancel_issue(cancel_message = ::I18n.t(:message_meeting_canceled))
    issue = self.issue
    cancel_status = IssueStatus.find(Setting.plugin_redmine_meeting[:cancel_issue_status])
    if issue.present?
      issue.init_journal(User.current, cancel_message)
      issue.status = cancel_status
      issue.save
    end
  end

  def cancel_issue_for_destroyed_member
    cancel_issue(::I18n.t(:message_meeting_member_destroyed))
  end

  def cancel_issue_for_destroyed_agenda
    cancel_issue(::I18n.t(:message_meeting_canceled))
  end

private
  def estimated_time_create(created_issue_id)
    EstimatedTime.create!(
      issue_id: created_issue_id,
      user_id: self.user_id,
      hours: (((self.meeting_agenda.end_time.seconds_since_midnight - self.meeting_agenda.start_time.seconds_since_midnight) / 36) / 100.0),
      comments: ::I18n.t(:message_participate_in_the_meeting),
      plan_on: self.meeting_agenda.meet_on,
    )
  end

  def key_words
    {
      subject: self.meeting_agenda.subject,
      meet_on: self.meeting_agenda.meet_on.strftime("%d.%m.%Y"),
      start_time: self.meeting_agenda.start_time.strftime("%H:%M"),
      end_time: self.meeting_agenda.end_time.strftime("%H:%M"),
      author: self.meeting_agenda.author.name,
      place: self.meeting_agenda.place_or_address,
      url: url_for(controller: 'meeting_agendas', action: 'show', id: self.meeting_agenda_id, only_path: false)
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

  def issue_attributes
    settings = Setting[:plugin_redmine_meeting]
    {status: IssueStatus.default,
    tracker: Tracker.find(settings[:issue_tracker]),
    subject: issue_subject,
    project: Project.find(settings[:project_id]),
    description: issue_description,
    author: User.current,
    start_date: Date.today,
    due_date: self.meeting_agenda.meet_on,
    priority: self.meeting_agenda.priority || IssuePriority.default,
    assigned_to: self.user}
  end

  def validate_meeting_agenda
    errors[:base] << ::I18n.t(:error_messages_meeting_agenda_not_valid)
  end
end
