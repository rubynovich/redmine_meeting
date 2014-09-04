require_dependency 'principal'
require_dependency 'user'

module MeetingPlugin
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
      end
    end

    module ClassMethods

    end

    module InstanceMethods
      def meeting_manager?
        begin
          principal = Principal.find(Setting.plugin_redmine_meeting[:principal_id])
          self.is_or_belongs_to?(principal)
        rescue
          nil
        end
      end

      def meeting_member?
        MeetingMember.where(user_id: self.id).present? || meeting_manager?
      end

      def meeting_participator?
        MeetingParticipator.where(user_id: self.id).present? || meeting_manager?
      end
    end
  end
end
