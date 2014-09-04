desc <<-END_DESC
Close solved notices about protocol.

Example:
  rake redmine:close_solved_notices RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :close_solved_notices => :environment do
    solved_status = Setting[:plugin_redmine_meeting][:solved_issue_status]
    MeetingParticipator.
      joins(:issue).
      where("issues.status_id = ?", solved_status).each do |member|
        p member.issue.update_attribute(:status_id, Setting[:plugin_redmine_meeting][:close_issue_status])
      end
  end
end
