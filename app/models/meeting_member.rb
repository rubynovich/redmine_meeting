class MeetingMember < ActiveRecord::Base
  unloadable

  belongs_to :meeting_agenda
  belongs_to :user
  belongs_to :issue
  has_one :status, through: :issue
  has_one :meeting_participator

  validates_uniqueness_of :user_id, scope: :meeting_agenda_id
  validates_presence_of :user_id, :meeting_agenda_id

  def to_s
    self.user.try(:name) || ''
  end
end
