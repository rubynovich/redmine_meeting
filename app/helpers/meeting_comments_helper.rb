module MeetingCommentsHelper
  def can_show_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end

  def can_create_comments?(container)
    admin? || meeting_manager? || container.users.include?(User.current)
  end
end
