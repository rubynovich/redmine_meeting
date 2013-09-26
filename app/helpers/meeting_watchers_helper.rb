module MeetingWatchersHelper
  def can_create_watcher?(item)
    admin?(item) || author?(item)
  end

  def can_destroy_watcher?(item)
    admin?(item) || author?(item)
  end
end
