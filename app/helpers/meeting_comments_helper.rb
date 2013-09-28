module MeetingCommentsHelper
  def admin?
    User.current.admin?
  end

  def author?(item)
    User.current == item.author
  end

  def can_show_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end

  def can_create_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end
end
