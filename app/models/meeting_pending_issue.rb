class MeetingPendingIssue < ActiveRecord::Base
  unloadable

  belongs_to :meeting_container, polymorphic: true
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :assigned_to, class_name: 'User', foreign_key: 'assigned_to_id'
  belongs_to :issue
  belongs_to :parent_issue, class_name: 'Issue', foreign_key: 'parent_issue_id'
  belongs_to :tracker, class_name: 'Tracker', foreign_key: 'tracker_id'

  def execute
    case self.issue_type
    when 'update'
      update_issue
      self.update_attribute(:executed_on, Time.now)
      self.update_attribute(:executed, true)
    when 'create'
      create_issue
      self.update_attribute(:executed_on, Time.now)
      self.update_attribute(:executed, true)
      self.update_attribute(:issue_id, @issue.try(:id))
    end
  end

  def create_issue
    @issue = Issue.create(
      assigned_to: self.assigned_to
      start_date: self.start_date,
      due_date: self.due_date,
      tracker: self.tracker,
      description: self.description,

    )
  end

  def update_issue
  end
end
