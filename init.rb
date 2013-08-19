Redmine::Plugin.register :redmine_meeting do
  name 'Redmine Meeting plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
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
