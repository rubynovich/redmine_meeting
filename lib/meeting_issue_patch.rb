require_dependency 'issue'
require_dependency 'issue_status'

module MeetingPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
#        has_one :meeting_member
#        before_save :add_estimated_times_from_meeting, ->{
#          self.meeting_member.present? &&
#          (self.issue_status == IssueStatus.find(Setting[:plugin_redmine_meeting][:solved_issue_status])) &&
#          (Issue.find(self.id).issue_status != IssueStatus.find(Setting[:plugin_redmine_meeting][:solved_issue_status]))
#        }
      end
    end

    module ClassMethods
    end

    module InstanceMethods
#      def add_estimated_times_from_meeting

#      end
    end
  end
end
