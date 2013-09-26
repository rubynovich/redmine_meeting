module MeetingWatchersHelper
  def can_create_watcher?(item)
    admin? || author?(item)
  end

  def can_destroy_watcher?(item)
    admin? || author?(item)
  end
end
