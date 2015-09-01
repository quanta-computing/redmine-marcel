require 'redmine'

Redmine::Plugin.register :marcel do
  name 'Marcel plugin'
  author 'Matthieu Rosinski <mro@quanta-computing.com>'
  description 'This is a Human Relations plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/quanta-computing/redmine-marcel-plugin'
  author_url 'http://quanta-computing.com/'

  menu :top_menu, :vacations, { controller: 'vacations', action: 'index'}, caption: 'Marcel'
  settings default: {
        allowed_edit_group_id: nil,
        reporting_group_id: nil,
      },
      partial: 'settings/marcel_settings'

  User.safe_attributes 'paid_vacation_days', 'recup_days', 'time_remind_level', if: lambda {|user, current_user| Marcel::is_admin?(current_user)}
  WorkingHours::Config.working_hours = Marcel::WORKING_HOURS
  WorkingHours::Config.time_zone = ActiveSupport::TimeZone[Marcel::TIMEZONE]
end
