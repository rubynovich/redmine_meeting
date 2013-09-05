module MeetingIssuesHelper
  def meeting_manager?
    User.current.meeting_manager?
  end

  def author?(item)
    item.author == User.current
  end

  def can_create_issue?(answer)
    meeting_manager? && author?(answer.meeting_protocol)
  end

  def can_update_issue?(answer)
    meeting_manager? && author?(answer.meeting_protocol) && answer.meeting_question.present? && answer.meeting_question.issue.present?
  end

  def can_destroy_issue?(answer)
    meeting_manager? && author?(answer.meeting_protocol)
  end

end
