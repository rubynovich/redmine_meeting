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
  validates_uniqueness_of :meeting_member_id, scope: [:user_id, :meeting_protocol_id], if: "self.meeting_member_id.present?"

  before_save :add_meeting_member

  def to_s
    self.member.try(:name) || self.user.try(:name)
  end

  def add_meeting_member
    self.meeting_member = MeetingMember.where(user_id: self.user_id, meeting_agenda_id: self.meeting_agenda.id).first
  end
end
