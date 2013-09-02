desc <<-END_DESC
Close outdate invites to meeting.

Example:
  rake redmine:close_outdate_invites RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :close_outdate_invites => :environment do
    MeetingMember.
      joins(:meeting_agenda).
      joins(:status).
      where("meeting_agendas.meet_on < ?", Date.today).
      where("issue_statuses.is_closed = ?", false).each do |member|
        p member.issue.update_attribute(:status_id, Setting[:plugin_redmine_meeting][:issue_status])
      end
  end
end
