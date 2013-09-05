module MeetingCommentsHelper
  def meeting_manager?
    User.current.meeting_manager?
  end

  def admin?
    User.current.admin?
  end

  def author?(item)
    item.author == User.current
  end

  def can_show_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end

  def can_create_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end
end
