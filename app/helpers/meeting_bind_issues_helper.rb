module MeetingBindIssuesHelper
  def can_bind_issue?(answer)
    (admin? || meeting_manager? && author?(answer.meeting_protocol))
  end
end
