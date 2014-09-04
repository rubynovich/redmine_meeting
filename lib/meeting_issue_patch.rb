require_dependency 'issue'
require_dependency 'issue_status'

module MeetingPlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :meeting_member
        before_save :add_estimated_times_from_meeting, if: ->{
          self.meeting_member.present? && self.id.present? &&
          (self.status_id == Setting[:plugin_redmine_meeting][:onwork_issue_status].try(:to_i)) &&
          (Issue.find(self.id).status_id != Setting[:plugin_redmine_meeting][:onwork_issue_status].try(:to_i))
        }
        before_save :del_estimated_times_from_meeting, if: ->{
          self.meeting_member.present? && self.id.present? &&
          (self.status == IssueStatus.find(Setting[:plugin_redmine_meeting][:cancel_issue_status])) &&
          (Issue.find(self.id).status != IssueStatus.find(Setting[:plugin_redmine_meeting][:cancel_issue_status]))
        }
        has_one :meeting_participator
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def add_estimated_times_from_meeting
        del_estimated_times_from_meeting
        EstimatedTime.create!(
          issue_id: self.id,
          user_id: self.meeting_member.user_id,
          hours: (((self.meeting_member.meeting_agenda.end_time.seconds_since_midnight - self.meeting_member.meeting_agenda.start_time.seconds_since_midnight) / 36) / 100.0),
          comments: ::I18n.t(:message_participate_in_the_meeting),
          plan_on: self.meeting_member.meeting_agenda.meet_on
        )
      end

      def del_estimated_times_from_meeting
        EstimatedTime.where(
          issue_id: self.id,
          user_id: self.meeting_member.user_id,
          plan_on: self.meeting_member.meeting_agenda.meet_on
        ).delete_all
      end
    end
  end
end
