class MeetingParticipator < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :user
  belongs_to :meeting_member
  belongs_to :issue
  has_one :status, through: :issue
  has_one :meeting_agenda, through: :meeting_protocol

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, scope: :meeting_protocol_id
  validates_uniqueness_of :meeting_member_id,
    scope: [:user_id, :meeting_protocol_id],
    if: -> {self.meeting_member_id.present?}
  validate :validate_meeting_protocol,
    if: -> {self.meeting_protocol.present? && !self.meeting_protocol.valid?}

  before_save :add_meeting_member
  before_destroy :cancel_issue_for_destroyed_participator, if: -> {self.issue.present?}

  def to_s
    self.member.try(:name) || self.user.try(:name) || ''
  end

  def cancel_issue(cancel_message)
    issue = self.issue
    cancel_status = IssueStatus.find(Setting.plugin_redmine_meeting[:cancel_issue_status])
    if issue.present?
      issue.init_journal(User.current, cancel_message)
      issue.status = cancel_status
      issue.save
    end
  end

  def cancel_issue_for_destroyed_participator
    cancel_issue(::I18n.t(:message_meeting_patricipator_destroyed))
  end

  def send_notice
    begin
      Mailer.meeting_participators_notice(self).deliver
    rescue
      nil
    end
  end

private
  def add_meeting_member
    self.meeting_member = MeetingMember.where(user_id: self.user_id, meeting_agenda_id: self.meeting_agenda.id).first
  end

  def validate_meeting_protocol
    errors[:base] << ::I18n.t(:error_messages_meeting_protocol_not_valid)
  end
end
