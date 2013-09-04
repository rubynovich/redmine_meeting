desc <<-END_DESC
Close solved notices about protocol.

Example:
  rake redmine:close_solved_notices RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :close_outdate_invites => :environment do
    default_status = IssueStatus.default
    MeetingParticipator.
      joins(:issue).
      where("issues.status_id <> ?", default_status.id).each do |member|
        p member.issue.update_attribute(:status_id, Setting[:plugin_redmine_meeting][:notice_issue_status])
      end
  end
end
