class MeetingAgenda < ActiveRecord::Base
  unloadable

  acts_as_attachable
  attr_accessor :project

  belongs_to :author, class_name: 'Person', foreign_key: 'author_id'
  belongs_to :priority, class_name: 'IssuePriority', foreign_key: 'priority_id'
  belongs_to :meeting_room_reserve, dependent: :destroy
  belongs_to :external_company, class_name: 'Contact', foreign_key: 'external_company_id'
  belongs_to :asserter, class_name: 'Person', foreign_key: 'asserter_id'
  belongs_to :external_asserter, class_name: 'Contact', foreign_key: 'external_asserter_id'
  belongs_to :meeting_company
  belongs_to :parent, class_name: 'MeetingAgenda', foreign_key: 'id'
  has_one :meeting_protocol
  has_many :meeting_questions, dependent: :delete_all, order: :position
  has_many :issues, through: :meeting_questions, order: :id, uniq: true
  has_many :projects, through: :issues, order: :title, uniq: true
  has_many :statuses, through: :issues, uniq: true
  has_many :meeting_members, dependent: :delete_all
  has_many :invites, through: :meeting_members, source: :issue
  has_many :users, through: :meeting_members, order: [:lastname, :firstname], uniq: true
  has_many :meeting_approvers, as: :meeting_container, dependent: :delete_all
  has_many :approvers, source: :person, through: :meeting_approvers, order: [:lastname, :firstname], uniq: true
  has_many :meeting_contacts, as: :meeting_container, dependent: :delete_all
  has_many :contacts, through: :meeting_contacts, order: [:last_name, :first_name], uniq: true
  has_many :meeting_external_approvers, as: :meeting_container, dependent: :delete_all
  has_many :external_approvers, through: :meeting_external_approvers, source: :contact, order: [:last_name, :first_name], uniq: true
  has_many :meeting_watchers, as: :meeting_container, dependent: :delete_all
  has_many :watchers, through: :meeting_watchers, order: [:lastname, :firstname], uniq: true
  has_many :meeting_comments, as: :meeting_container, order: ["created_on DESC"], dependent: :delete_all, uniq: true

  accepts_nested_attributes_for :meeting_questions, allow_destroy: true
  accepts_nested_attributes_for :meeting_members, allow_destroy: true
  accepts_nested_attributes_for :meeting_contacts, allow_destroy: true
  accepts_nested_attributes_for :meeting_watchers, allow_destroy: true

  attr_accessible :meeting_members_attributes
  attr_accessible :meeting_questions_attributes
  attr_accessible :meeting_contacts_attributes
  attr_accessible :meeting_watchers_attributes
  attr_accessible :subject, :place, :meet_on, :start_time, :end_time, :priority_id, :external_company_id
  attr_accessible :is_external, :asserter_id, :meeting_company_id
  attr_accessible :asserter_id_is_contact, :external_asserter_id, :address
  attr_accessible :external_place_type
  attr_accessible :asserter_invite_on

  validates_uniqueness_of :subject, scope: :meet_on
  validates_presence_of :subject, :meet_on, :start_time, :end_time, :priority_id
  validates_presence_of :place, unless: -> { self.is_external? }
  validates_presence_of :external_company_id, if: -> { self.is_external? && self.external_place_type && self.external_place_type["external_company"] }
  validates_presence_of :address, if: -> { self.is_external? && self.external_place_type && self.external_place_type["building_object"] }
  validates_presence_of :asserter_id, unless: -> { self.asserter_id_is_contact? }
  validates_presence_of :external_asserter_id, if: -> { self.asserter_id_is_contact? }
  validates_presence_of :meeting_company_id
  validate :end_time_less_than_start_time, if: -> { self.start_time && self.end_time && (self.end_time <= self.start_time) }
  validate :meet_on_less_than_today, if: -> { self.meet_on && (self.meet_on < Date.today) }
  validate :start_time_less_than_now, if: -> {
    self.meet_on && (self.meet_on == Date.today) &&
    self.start_time && (self.start_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  }
  validate :end_time_less_than_now, if: -> {
    self.meet_on && (self.meet_on == Date.today) &&
    self.end_time && (self.end_time.seconds_since_midnight < Time.now.seconds_since_midnight)
  }
  validate :presence_of_meeting_questions, if: -> { self.meeting_questions.blank? }
  validate :presence_of_meeting_members, if: -> { self.meeting_members.blank? }
  validate :meeting_room_reserve_validation, if: -> { MeetingRoom.where("LOWER(name) = LOWER(?)", self.place).present? && !self.is_external? }
  validate :meeting_question_title_uniq, if: -> { mq = self.meeting_questions.map(&:title); mq.size != mq.uniq.size }

  before_create :add_author_id
  after_save :add_new_users_from_questions
  after_save :add_new_contacts_from_questions
  after_create :new_meeting_room_reserve, if: -> { MeetingRoom.where("LOWER(name) = LOWER(?)", self.place).present? && !self.is_external? }
  after_update :update_meeting_room_reserve, if: -> { MeetingRoom.where("LOWER(name) = LOWER(?)", self.place).present? && !self.is_external? }


  scope :active, -> {
    where('meeting_agendas.is_deleted' => false)
  }

  scope :free, -> {
    where("id NOT IN (SELECT meeting_agenda_id FROM meeting_protocols)")
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

  scope :eql_project_id, ->(q) {
    if q.present?
      joins(meeting_questions: :issue).where("issues.project_id = ?", q)
    end
  }

  def place_or_address
    if self.is_external?
      address
    else
      self.place
    end
  end

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_deletable?(user=User.current)
    false
  end

  def to_s
    self.subject
  end

  def address
    if super.blank? && self.external_company.present?
      self.external_company.address
    else
      super
    end
  end

  def new_user_ids_from_questions
    new_user_ids = self.meeting_questions.reject(&:user_id_is_contact).map(&:user_id)
    (new_user_ids - self.user_ids).compact.uniq
  end

  def new_contact_ids_from_questions
    new_contact_ids = self.meeting_questions.select(&:user_id_is_contact).map(&:contact_id)
    new_contact_ids << self.external_asserter_id if self.asserter_id_is_contact?
    (new_contact_ids - self.contact_ids).compact.uniq
  end

  def approved?
    self.meeting_approvers.reject(&:deleted).all?(&:approved?)
  end

private
  def add_author_id
    self.author_id = User.current.id
  end

  def end_time_less_than_start_time
    errors.add(:end_time, :less_than_start_time)
  end

  def meet_on_less_than_today
    errors.add(:meet_on, :less_than_today)
  end

  def start_time_less_than_now
    errors.add(:start_time, :less_than_now)
  end

  def end_time_less_than_now
    errors.add(:end_time, :less_than_now)
  end

  def presence_of_meeting_questions
    errors[:base] << ::I18n.t(:error_messages_meeting_questions_must_exist)
  end

  def presence_of_meeting_members
    if self.meeting_questions.blank? || self.meeting_questions.all?{ |q| q.user.blank? }
      errors.add(:meeting_members, :must_exist)
    end
  end

  def meeting_room_reserve_attributes
    {user_id: User.current.id,
    subject: self.subject,
    meeting_room_id: find_meeting_room.id,
    reserve_on: self.meet_on,
    start_time: self.start_time,
    end_time: self.end_time}
  end

  def meeting_room_reserve_new
    MeetingRoomReserve.new(meeting_room_reserve_attributes)
  end

  def find_meeting_room
    MeetingRoom.where("LOWER(name) = LOWER(?)", self.place).first
  end

  def meeting_room_reserve_validation
    reserve = if self.meeting_room_reserve.present?
      meeting_room_reserve_attributes.inject(self.meeting_room_reserve){ |result, array|
        result.send("#{array[0]}=", array[1])
        result
      }
    else
      meeting_room_reserve_new
    end
    unless reserve.valid?
      errors[:base] << ::I18n.t(:error_messages_meeting_room_not_reserved)
    end
  end

  def meeting_question_title_uniq
    errors[:base] << ::I18n.t(:error_messages_meeting_question_title_not_uniq)
  end

  def new_meeting_room_reserve
    mrr = meeting_room_reserve_new
    if mrr.save
      self.update_attribute(:meeting_room_reserve_id, mrr.id)
    end
  end

  def update_meeting_room_reserve
    if self.meeting_room_reserve.present?
      self.meeting_room_reserve.update_attributes(meeting_room_reserve_attributes)
    else
      new_meeting_room_reserve
    end
  end

  def add_new_users_from_questions
    new_user_ids_from_questions.each do |user_id|
      MeetingMember.create(user_id: user_id, meeting_agenda_id: self.id)
    end
  end

  def add_new_contacts_from_questions
    new_contact_ids_from_questions.each do |contact_id|
      MeetingContact.create(meeting_container_type: self.class.to_s, meeting_container_id: self.id, contact_id: contact_id)
    end
  end
end
