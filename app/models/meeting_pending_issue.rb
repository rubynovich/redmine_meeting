class MeetingPendingIssue < ActiveRecord::Base
  unloadable

  belongs_to :meeting_container, polymorphic: true
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :assigned_to, class_name: 'User', foreign_key: 'assigned_to_id'
  belongs_to :project
  belongs_to :tracker, class_name: 'Tracker', foreign_key: 'tracker_id'
  belongs_to :priority, class_name: 'IssuePriority', foreign_key: 'priority_id'
  belongs_to :status, class_name: 'IssueStatus', foreign_key: 'status_id'
  has_one :issue, through: :meeting_container

  validates_uniqueness_of :meeting_container_id, scope: :meeting_container_type
#  validates_presence_of :subject, :project_id, if: ->(o) { o.issue_note.blank? }
#  validates_presence_of :issue_note, if: ->(o) { o.tracker_id.blank? }
  validates_presence_of :author_id, :meeting_container_id, :meeting_container_type
#  validate :can_update_issue, if: -> { self.tracker_id.blank? }
  validate :can_create_issue, if: ->(object) { object.tracker.present? }


  def watched_by?(user)
    true
  end

  def css_classes
    "issue tracker-#{tracker_id} status-#{status_id} #{priority.try(:css_classes)}"
  end

  def done_ratio
    if self.meeting_container.issue_id && self.executed?
      self.issue.done_ratio
    else
      0
    end
  end

#  def can_update_issue
#    if issue = self.meeting_container.issue
#      issue.init_journal(User.current, self.issue_note)
#      issue.status = IssueStatus.default
#      unless issue.valid?
#        errors = issue.errors
#      end
#    end
#  end

  def can_create_issue
    issue = Issue.new(issue_attributes)
    issue.author = self.author
    issue.parent_issue_id = self.parent_issue_id
    unless issue.valid?
      errors = issue.errors
    end
  end

  def execute
    unless self.executed?
      if (case self.meeting_container.issue_type
        when 'update' then update_issue
        when 'new' then create_issue
        end)
        self.update_attribute(:executed_on, Time.now)
        self.update_attribute(:executed, true)
      end
    end
  end

  def issue_attributes
    {tracker: self.tracker,
    project: self.project,
    subject: self.subject,
    description: self.description,
    priority: self.priority,
    status: self.status,
    assigned_to: self.assigned_to,
    start_date: self.start_date,
    due_date: self.due_date}
  end

  def create_issue
    @issue = Issue.new(issue_attributes)
    @issue.author = self.author
    @issue.parent_issue_id  = self.parent_issue_id
    @issue.watcher_user_ids = self.watcher_user_ids
    if @issue.save
      self.meeting_container.update_attribute(:issue_id, @issue.id)
    end
  end

  def update_issue
    @issue = self.meeting_container.issue
    @issue.init_journal(User.current, self.issue_note)
    @issue.status = IssueStatus.default
    @issue.save
  end

  def watcher_user_ids=(array)
    super(array.to_yaml)
  end

  def watcher_user_ids
    YAML.load(super)
  end
end
