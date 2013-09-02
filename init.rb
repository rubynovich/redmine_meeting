require_dependency 'custom_field'

Redmine::Plugin.register :redmine_meeting do
  name 'Meeting'
  author 'Roman Shipiev'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://bitbucket.org/gorkapstroy/redmine_meeting'
  author_url 'http://roman.shipiev.me'

  settings partial: 'meeting_members/settings', default: {
    issue_priority: IssuePriority.default.id,
    subject: "%subject% %place% %meet_on% %start_time% %end_time%",
    description: "%url%",
    note: "%question%\n\n%description%\n\n%url%"
  }
end

Rails.configuration.to_prepare do
  require_dependency 'meeting_agenda'
  require_dependency 'meeting_protocol'
  require 'time_period_scope'

  [
   [MeetingAgenda, TimePeriodScope],
   [MeetingProtocol, TimePeriodScope]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
