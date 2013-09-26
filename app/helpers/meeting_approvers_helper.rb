module MeetingApproversHelper
  def can_create_approver?(item)
    author?(item) || admin?
  end

  def can_destroy_approver?(meeting_approver)
    (author?(meeting_approver.meeting_container) || admin?) &&
      !meeting_approver.deleted? && !meeting_approver.approved?
  end
end
