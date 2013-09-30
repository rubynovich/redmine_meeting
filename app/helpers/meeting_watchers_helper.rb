module MeetingWatchersHelper
  def admin?
    User.current.admin?
  end

  def author?(item)
    item.author == User.current
  end

  def can_create_watcher?(item)
    admin? || author?(item)
  end

  def can_destroy_watcher?(item)
    admin? || author?(item)
  end
end
