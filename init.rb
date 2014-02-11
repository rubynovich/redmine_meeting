require_dependency 'custom_field'
require 'prawn'
require 'reports/meeting_agenda_report'
require 'reports/meeting_protocol_report'

Redmine::Plugin.register :redmine_meeting do
  name 'Meeting'
  author 'Roman Shipiev'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://bitbucket.org/gorkapstroy/redmine_meeting'
  author_url 'http://roman.shipiev.me'

  requires_redmine version_or_higher: '2.3.2'
#  requires_redmine_plugin :redmine_planning, version_or_higher: '0.1.0'
#  requires_redmine_plugin :redmine_meeting_rooms, version_or_higher: '0.1.0'

  settings partial: 'plugin_redmine_meeting/settings', default: {
    issue_priority: IssuePriority.default.id,
    principal_id: User.where(admin: true).first.try(:id),
    subject: "%subject% %place% %meet_on% %start_time% %end_time%",
    description: "%url%",
    note: "%question%\n\n%description%\n\n%url%",
    notice_subject: "%subject% %place% %meet_on% %start_time% %end_time%",
    notice_description: "%url%",
    notice_duration: 1
  }

  menu :application_menu, :meeting_agendas,
    {controller: 'meeting_agendas', action: 'index'},
    caption: :label_meeting_agenda_plural,
    param: 'project_id',
    if: Proc.new { User.current.meeting_member? }

  menu :application_menu, :meeting_protocols,
    {controller: 'meeting_protocols', action: 'index'},
    caption: :label_meeting_protocol_plural,
    param: 'project_id',
    if: Proc.new { User.current.meeting_participator? }
end

Rails.configuration.to_prepare do
  require_dependency 'meeting_agenda'
  require_dependency 'meeting_protocol'
  require_dependency 'mailer'
  require 'time_period_scope'
  require 'meeting_user_patch'
  require 'meeting_issue_patch'
  require 'meeting_mailer_patch'
  require 'meeting_prawn_table_cell_patch'

  [
   [MeetingAgenda, TimePeriodScope],
   [MeetingProtocol, TimePeriodScope],
   [Issue, MeetingPlugin::IssuePatch],
   [User, MeetingPlugin::UserPatch],
   [Mailer, MeetingPlugin::MailerPatch],
   [Prawn::Table::Cell, MeetingPlugin::PrawnTableCellPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
