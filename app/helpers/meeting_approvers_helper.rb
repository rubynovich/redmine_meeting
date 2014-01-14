module MeetingApproversHelper
#  def admin?
#    User.current.admin?
#  end

#  def author?(item)
#    User.current.id == item.author_id
#  end

  def can_create_approver?(item)
    (author?(item) || admin?) && (!asserted?(item) || item.asserter_id_is_contact?)
  end

  def can_destroy_approver?(meeting_approver)
    item = meeting_approver.meeting_container
    (author?(item) || admin?) &&
      !meeting_approver.deleted? && !meeting_approver.approved? &&
      (!asserted?(item) || item.asserter_id_is_contact?)
  end
end
