module MeetingExternalApproversHelper
  def admin?
    User.current.admin?
  end

  def author?(item)
    User.current.id == item.author_id
  end

  def asserter?(item)
    (item.asserter_id == User.current.id) && !item.asserter_id_is_contact?
  end

  def asserted?(agenda)
    (agenda.asserted? ||
      (agenda.asserter_id_is_contact? &&
        agenda.meeting_approvers.reject(&:deleted).all?(&:approved?)))
  end

  def can_create_external_approver?(item)
    (author?(item) || admin?) && (!asserted?(item) || item.asserter_id_is_contact?)
  end

  def can_destroy_external_approver?(meeting_approver)
    item = meeting_approver.meeting_container
    (author?(item) || admin?) &&
      (!asserted?(item) || item.asserter_id_is_contact?)
  end
end
