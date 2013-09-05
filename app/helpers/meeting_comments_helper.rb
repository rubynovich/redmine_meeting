module MeetingCommentsHelper
  def meeting_manager?
    User.current.meeting_manager?
  end

  def author?(item)
    item.author == User.current
  end

  def can_show_comments?(container)
    meeting_manager? || container.users.include?(User.current)
  end

  def can_create_comments?(container)
    meeting_manager? || container.users.include?(User.current)
  end
end
