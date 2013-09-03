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
    principal_id: User.where(admin: true).first.try(:id),
    subject: "%subject% %place% %meet_on% %start_time% %end_time%",
    description: "%url%",
    note: "%question%\n\n%description%\n\n%url%"
  }

  menu :application_menu, :meeting_agendas,
    {controller: 'meeting_agendas', action: 'index'},
    caption: :label_meeting_agenda_plural,
    param: 'project_id',
    if: Proc.new{
      User.current.meeting_member?
    }

  menu :application_menu, :meeting_protocols,
    {controller: 'meeting_protocols', action: 'index'},
    caption: :label_meeting_protocol_plural,
    param: 'project_id',
    if: Proc.new{
      User.current.meeting_participator?
    }
end

Rails.configuration.to_prepare do
  require_dependency 'meeting_agenda'
  require_dependency 'meeting_protocol'
  require 'time_period_scope'
  require 'meeting_user_patch'

  [
   [MeetingAgenda, TimePeriodScope],
   [MeetingProtocol, TimePeriodScope],
   [User, MeetingPlugin::UserPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
