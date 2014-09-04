module MeetingParticipatorsHelper
  def accepter?(member)
    member.present? &&
    (member.user_id == User.current.id)
  end

  def can_accept?(member)
    member.present? &&
    member.sended_notice_on.present? &&
    member.saw_protocol_on.blank? &&
    accepter?(member)
  end

  def participator_notice_status(participator)
    if participator.present? && participator.sended_notice_on.present?
      l(:label_meeting_member_invited)
    else
      l(:label_meeting_member_was_not_invite)
    end
  end
end
