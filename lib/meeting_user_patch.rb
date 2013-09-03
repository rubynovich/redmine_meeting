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
          principal = Principal.find(Setting[:plugin_redmine_meeting][:principal_id])
          if principal.is_a?(Group)
            principal.users.include?(self)
          elsif principal.is_a?(User)
            principal == self
          end
        rescue
          nil
        end
      end

      def meeting_member?
        MeetingMember.where(user_id: self.id).count.nonzero? || meeting_manager?
      end

      def meeting_participator?
        MeetingParticipator.where(user_id: self.id).count.nonzero? || meeting_manager?
      end
    end
  end
end
