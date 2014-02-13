require_dependency 'issue'
require_dependency 'issue_status'
require_dependency 'issue_observer'

module MeetingPlugin
  module IssueObserverPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :after_create, :meeting_events
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def after_create_with_meeting_events(issue)
        if issue.meeting_member.blank? && issue.meeting_participator.blank?
          after_create_without_meeting_events(issue)
        end
      end
    end
  end
end
