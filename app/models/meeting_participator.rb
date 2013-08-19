class MeetingParticipator < ActiveRecord::Base
  unloadable

  belongs_to :meeting_protocol
  belongs_to :user
  belongs_to :meeting_member
  has_one :member, through: :meeting_member
  has_one :issue, through: :meeting_member
  has_one :status, through: :issue

  def to_s
    self.member.try(:name) || self.user.try(:name)
  end
end
