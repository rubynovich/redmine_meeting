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
      if Redmine::Plugin.all.map(&:id).include?(:redmine_vacation)
        if vacation_range = member.meeting_agenda.member_on_vacation?(member.user)
          return l(:label_meeting_member_was_not_invite_but_on_vacation, {:from => vacation_range.start_date.strftime("%d.%m.%Y"), :to => vacation_range.end_date.strftime("%d.%m.%Y")})
        end
      end
      l(:label_meeting_member_was_not_invite)
    end
  end
end
