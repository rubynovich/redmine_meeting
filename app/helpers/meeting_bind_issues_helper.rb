module MeetingBindIssuesHelper
  def can_bind_issue?(answer)
    (admin? || meeting_manager? && author?(answer.meeting_protocol)) && answer.meeting_question.present? && answer.meeting_question.issue.blank?
  end

  def can_unbind_issue?(answer)
    (admin? || meeting_manager? && author?(answer.meeting_protocol)) && answer.meeting_question.present? && answer.meeting_question.issue.present?
  end
end
