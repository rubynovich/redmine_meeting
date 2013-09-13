module MeetingPlugin
  module MailerPatch
    def self.included(base)

      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        include Rails.application.routes.url_helpers
      end

    end

    module ClassMethods
      def meeting_approver_create(approver)
        author = approver.author
        user = approver.user
        container = approver.meeting_container
        mail_meeting_approver_create(author, user, container)
      end

      def meeting_approver_destroy(approver)
        author = approver.author
        user = approver.user
        container = approver.meeting_container
        mail_meeting_approver_destroy(author, user, container)
      end

      def meeting_approver_approve(approver)
        author = approver.author
        user = approver.user
        container = approver.meeting_container
        mail_meeting_approver_approve(author, user, container)
      end

      def meeting_comment_create(comment)
        author = comment.meeting_container.author
        user = comment.author
        container = if comment.meeting_container_type == 'MeetingQuestion'
          comment.meeting_container.meeting_agenda
        elsif comment.meeting_container_type == 'MeetingAnswer'
          comment.meeting_container.meeting_protocol
        end
        comment = comment.note
        mail_meeting_comment_create(author, user, container, comment)
      end
    end

    module InstanceMethods
      def mail_meeting_approver_create(author, user, container)
        @username = user.name
        @authorname = author.name
        @container = container
        type = {MeetingAgenda => ::I18n.t(:label_meeting_agenda), MeetingProtocol => ::I18n.t(:label_meeting_protocol)}[container.class]
        subject = ::I18n.t(:message_subject_meeting_approver_create, author: @authorname, type: type)

        mail(to: user.mail, subject: subject)
      end

      def mail_meeting_approver_destroy(author, user, container)
        @username = user.name
        @authorname = author.name
        @container = container
        type = {MeetingAgenda => ::I18n.t(:label_meeting_agenda), MeetingProtocol => ::I18n.t(:label_meeting_protocol)}[container.class]
        subject = ::I18n.t(:message_subject_meeting_approver_destroy, author: @authorname, type: type)

        mail(to: user.mail, subject: subject)
      end

      def mail_meeting_approver_approve(author, user, container)
        @username = user.name
        @authorname = author.name
        @container = container
        type = {MeetingAgenda => ::I18n.t(:label_meeting_agenda), MeetingProtocol => ::I18n.t(:label_meeting_protocol)}[container.class]
        subject = ::I18n.t(:message_subject_meeting_approver_approve, user: @username, type: type)

        mail(to: author.mail, subject: subject)
      end

      def mail_meeting_comment_create(author, user, container, comment)
        @username = user.name
        @authorname = author.name
        @container = container
        @comment = comment
        type = {MeetingAgenda => ::I18n.t(:label_meeting_agenda), MeetingProtocol => ::I18n.t(:label_meeting_protocol)}[container.class]
        subject = ::I18n.t(:message_subject_meeting_comment_create, user: @username, type: type)

        mail(to: author.mail, subject: subject)
      end

#      def mail_meeting_approver_create(author, user, container)
#        set_language_if_valid user.language
#        mail(to: user.mail, subject: @subject)
#        @issues = issues
#        issues_count = @issues.count

#        @conjugation = case issues_count
#                         when 1    then 1
#                         when 2..4 then 2
#                         else           5
#                       end

#        @subject = l(:"#{@conjugation}", scope: "mail_subject_approval_items", :count => issues_count)
#        @body = l(:"#{@conjugation}", scope: "mail_body_approval_items", :count => issues_count)

#        @username = user.name

#        mail(to: user.mail, subject: @subject)

#      end

    end
  end
end
