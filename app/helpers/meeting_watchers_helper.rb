module MeetingWatchersHelper
  def admin?
    User.current.admin?
  end

  def author?(item)
    item.author_id == User.current.id
  end

  def can_create_watcher?(item)
    admin? || author?(item)
  end

  def can_destroy_watcher?(item)
    admin? || author?(item)
  end
end
