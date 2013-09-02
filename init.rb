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

  permission :view_meeting_agendas, meeting_agendas: [:index, :show]
  permission :add_meeting_agendas, meeting_agendas: [:new, :create]
  permission :edit_meeting_agendas, meeting_agendas: [:edit, :update]
  permission :delete_meeting_agendas, meeting_agendas: [:destroy]

  permission :view_meeting_protocols, meeting_protocols: [:index, :show]
  permission :add_meeting_protocols, meeting_protocols: [:new, :create]
  permission :edit_meeting_protocols, meeting_protocols: [:edit, :update]
  permission :delete_meeting_protocols, meeting_protocols: [:destroy]

  menu :application_menu, :meeting_agendas,
    {controller: 'meeting_agendas', action: 'index'},
    caption: :label_meeting_agenda_plural,
    param: 'project_id',
    if: -> {
      User.current.allowed_to?({controller: 'meeting_agendas', action: 'index'}, nil, {global: true})
    }

  menu :application_menu, :meeting_protocols,
    {controller: 'meeting_protocols', action: 'index'},
    caption: :label_meeting_protocol_plural,
    param: 'project_id',
    if: -> {
      User.current.allowed_to?({controller: 'meeting_protocols', action: 'index'}, nil, {global: true})
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
