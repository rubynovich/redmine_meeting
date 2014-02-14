class MeetingProtocol < ActiveRecord::Base
  unloadable

  acts_as_attachable
  attr_accessor :project

  belongs_to :author, class_name: 'Person', foreign_key: 'author_id'
  belongs_to :meeting_agenda
  belongs_to :asserter, class_name: 'Person', foreign_key: 'asserter_id'
  belongs_to :external_asserter, class_name: 'Contact', foreign_key: 'external_asserter_id'
  belongs_to :meeting_company
  belongs_to :parent, class_name: 'MeetingProtocol', foreign_key: 'id'
  has_one  :external_company, through: :meeting_agenda
  has_many :meeting_answers, dependent: :delete_all
  has_many :meeting_extra_answers, dependent: :delete_all
  has_many :issues, through: :meeting_answers, uniq: true
  has_many :meeting_participators, dependent: :delete_all
  has_many :users, through: :meeting_participators, order: [:lastname, :firstname], uniq: true
  has_many :meeting_members, through: :meeting_agenda, uniq: true
  has_many :meeting_approvers, as: :meeting_container, dependent: :delete_all
  has_many :approvers, through: :meeting_approvers, source: :person
  has_many :meeting_contacts, as: :meeting_container, dependent: :delete_all
  has_many :contacts, through: :meeting_contacts, order: [:last_name, :first_name], uniq: true
  has_many :meeting_external_approvers, as: :meeting_container, dependent: :delete_all
  has_many :external_approvers, through: :meeting_external_approvers, source: :contact, order: [:last_name, :first_name], uniq: true
  has_many :meeting_watchers, as: :meeting_container, dependent: :delete_all
  has_many :watchers, through: :meeting_watchers, order: [:lastname, :firstname], uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true

  delegate :meet_on, :subject, :place, :address, :is_external, :is_external?,
    :to_s, to: :meeting_agenda, allow_nil: true

  accepts_nested_attributes_for :meeting_answers, allow_destroy: true
  accepts_nested_attributes_for :meeting_extra_answers, allow_destroy: true
  accepts_nested_attributes_for :meeting_participators, allow_destroy: true
  accepts_nested_attributes_for :meeting_contacts, allow_destroy: true
  accepts_nested_attributes_for :meeting_watchers, allow_destroy: true

  attr_accessible :meeting_answers_attributes
  attr_accessible :meeting_extra_answers_attributes
  attr_accessible :meeting_participators_attributes
  attr_accessible :meeting_contacts_attributes
  attr_accessible :meeting_watchers_attributes
  attr_accessible :meeting_agenda_id, :start_time, :end_time, :asserter_id, :meeting_company_id
  attr_accessible :external_asserter_id, :asserter_id_is_contact
  attr_accessible :asserter_invite_on

#  validates_uniqueness_of :meeting_agenda_id, message: :has_already_been_used_to_create_protocol
  validates_presence_of :meeting_agenda_id, :meeting_company_id
  validates_presence_of :external_asserter_id, if: -> { self.asserter_id_is_contact? }
  validates_presence_of :asserter_id, unless: -> { self.asserter_id_is_contact? }
  validate :presence_of_meeting_answers, if: -> {self.meeting_answers.blank?}
  validate :presence_of_meeting_participators, if: -> {self.meeting_participators.blank?}
  validate :presence_of_start_time, if: -> {self.start_time.blank? || self.start_time.seconds_since_midnight.zero?}
  validate :presence_of_end_time, if: -> {self.end_time.blank? || self.end_time.seconds_since_midnight.zero?}
  validate :end_time_less_than_start_time, if: -> {
    self.start_time && self.end_time && (self.end_time.seconds_since_midnight < self.start_time.seconds_since_midnight)
  }
  validate :uniqueness_of_meeting_agenda_id, on: :create

  before_create :add_author_id
  after_create :add_new_users_from_answers
  after_create :add_new_contacts_from_answers
  after_save :add_time_entry_to_invites

  scope :active, -> {
    where('meeting_protocols.is_deleted' => false)
  }

  scope :like_field, ->(q, field) {
    if q.present? && field.present?
      where("LOWER(#{field}) LIKE LOWER(?)", "%#{q.to_s.downcase}%")
    end
  }

  scope :eql_field, ->(q, field) {
    if q.present? && field.present?
      where("#{field} = ?", q)
    end
  }

  scope :eql_project_id, ->(q) {
    if q.present?
      joins(meeting_answers: :issue).where("issues.project_id = ?", q)
    end
  }

  scope :bool_field, ->(q, field) {
    if q.present? && field.present?
      case q
        when 'true'
          where("#{field} = ?", true)
        when 'false'
          where("#{field} = ?", false)
      end
    end
  }

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    false
  end

  def all_meeting_answers
    self.meeting_answers + self.meeting_extra_answers
  end

#  def to_s
#    self.meeting_agenda.to_s
#  end

#  def meet_on
#    self.meeting_agenda.meet_on
#  end

#  def subject
#    self.meeting_agenda.subject
#  end

#  def place
#    self.meeting_agenda.place
#  end

#  def address
#    self.meeting_agenda.address
#  end

#  def is_external?
#    self.meeting_agenda.is_external?
#  end

#  def is_external
#    self.meeting_agenda.is_external
#  end

  def new_user_ids_from_answers
    new_user_ids = self.all_meeting_answers.reject(&:reporter_id_is_contact).map(&:reporter_id)
    (new_user_ids - self.user_ids).compact.uniq
  end

  def new_contact_ids_from_answers
    new_contact_ids = self.all_meeting_answers.select(&:reporter_id_is_contact).map(&:external_reporter_id)
    new_contact_ids += self.all_meeting_answers.select(&:user_id_is_contact).map(&:external_user_id)
    (new_contact_ids - self.contact_ids).compact.uniq
  end

  def send_notices
    begin
      if self.meeting_participators.all?(&:sended_notice_on)
        self.meeting_participators.all?(&:send_notice)
      else
        self.meeting_participators.reject(&:sended_notice_on).all?(&:send_notice)
      end
      self.meeting_contacts.all?(&:send_notice)
      execute_pending_issues
      self.save
#    rescue
#      false
    end
  end

  def assert
    begin
      Mailer.meeting_protocol_asserted(self).deliver
      self.asserted = true
      self.asserted_on = Time.now
      self.save
    rescue
      false
    end
  end

  def send_asserter_invite
    begin
      Mailer.meeting_asserter_invite(self).deliver
      self.asserter_invite_on = Time.now
      self.save
    rescue
      false
    end
  end

  def restore
    self.is_deleted = false
    self.save
  end

  def mark_as_deleted
    self.is_deleted = true
    self.save
  end

private

  def add_time_entry_to_invites
    self.meeting_members.select(&:meeting_participator).select(&:issue).each do |member|
      if member.time_entry
        member.update_attribute(:hours, (((self.end_time.seconds_since_midnight - self.start_time.seconds_since_midnight) / 36) / 100.0))
      elsif self.end_time.present? && self.start_time.present?
        te = TimeEntry.new(
          issue_id: member.issue_id,
          hours: (((self.end_time.seconds_since_midnight - self.start_time.seconds_since_midnight) / 36) / 100.0),
          comments: ::I18n.t(:message_participate_in_the_meeting),
          spent_on: self.meeting_agenda.meet_on
        )
        te.user = member.user
        te.save
      end
    end
  end

  def presence_of_meeting_answers
    errors[:base] << ::I18n.t(:error_messages_meeting_answers_must_exist)
  end

  def presence_of_meeting_participators
    if self.meeting_answers.blank? || self.meeting_answers.all?{ |a| a.user.blank? }
      errors.add(:meeting_participators, :must_exist)
    end
  end

  def presence_of_start_time
    errors.add(:start_time, :empty)
  end

  def presence_of_end_time
    errors.add(:end_time, :empty)
  end

  def end_time_less_than_start_time
    errors.add(:end_time, :less_than_start_time)
  end

  def uniqueness_of_meeting_agenda_id
    if MeetingProtocol.where(meeting_agenda_id: self.meeting_agenda_id, is_deleted: false).present?
      errors.add(:meeting_agenda_id, :has_already_been_used_to_create_protocol)
    end
  end

  def add_author_id
    self.author_id = User.current.id
  end

  def add_new_users_from_answers
    new_user_ids_from_answers.each do |user_id|
      MeetingParticipator.create(user_id: user_id, meeting_protocol_id: self.id)
    end
  end

  def add_new_contacts_from_answers
    new_contact_ids_from_answers.each do |contact_id|
      MeetingContact.create(meeting_container_type: self.class.to_s, meeting_container_id: self.id, contact_id: contact_id)
    end
  end

  def execute_pending_issues
    (self.meeting_answers + self.meeting_extra_answers).
      select(&:pending_issue).map(&:pending_issue).map(&:execute)
  end
end
