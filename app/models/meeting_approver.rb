class MeetingApprover < ActiveRecord::Base
  unloadable

  validates_presence_of :meeting_container_id, :meeting_container_type, :user_id
  validates_presence_of :approved_on, if: -> { self.approved? }
  validates_uniqueness_of :user_id,  scope: [:meeting_container_id, :meeting_container_type]

  belongs_to :user
  belongs_to :person, foreign_key: 'user_id', class_name: 'Person'
  belongs_to :author, foreign_key: 'author_id', class_name: 'User'
  belongs_to :meeting_container, polymorphic: true

  before_validation :add_approved_on, if: -> do
    self.approved? && self.id && !self.class.find(self.id).approved?
  end
  before_create :add_author_id
  after_create :message_approver_create
  before_update :message_approver_create, if: -> do
    !self.deleted? && self.class.find(self.id).deleted?
  end
  before_update :message_approver_destroy, if: -> do
    self.deleted? && !self.class.find(self.id).deleted?
  end
  before_update :message_approver_approve, if: -> do
    self.approved? && !self.class.find(self.id).approved?
  end
  before_update :message_asserter_invite, if: -> do
    old_object = self.class.find(self.id)
    self.approved? && !old_object.approved? &&
    !meeting_container.asserter_id_is_contact? &&
    (meeting_container.meeting_approvers - [old_object]).reject(&:deleted).all?(&:approved?)
  end

  scope :open, ->(status = true) do
    where("#{self.table_name}.deleted = ?", !status)
  end

  scope :deleted, ->(status = true) do
    where("#{self.table_name}.deleted = ?", status)
  end

  def to_s
    user.to_s
  end

private
  def message_approver_approve
    Mailer.meeting_approver_approve(self).deliver
  end

  def message_approver_create
    Mailer.meeting_approver_create(self).deliver
  end

  def message_approver_destroy
    Mailer.meeting_approver_destroy(self).deliver
  end

  def message_asserter_invite
    Mailer.meeting_asserter_invite(self.meeting_container).deliver
  end

  def add_approved_on
    self.approved_on = Time.now
  end

  def add_author_id
    self.author_id = User.current.id
  end
end
