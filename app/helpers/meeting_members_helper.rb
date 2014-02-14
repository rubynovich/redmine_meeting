module MeetingMembersHelper
  def accepter?(member)
    member.user_id == User.current.id
  end

  def can_accept?(member)
    member.issue.present? &&
    (member.issue.status == IssueStatus.default) &&
    accepter?(member)
  end

  def link_to_invite(member)
    if member.present? && member.issue.present?
      link_to(member.issue.status, controller: 'issues', action: 'show', id: member.issue_id)
    else
      l(:label_meeting_member_was_not_invite)
    end
  end
end
