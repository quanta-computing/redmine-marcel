require 'slack'

namespace :marcel do
  namespace :reminder do

    desc 'Remind all users to update their times (via slack)'
    task slack: :environment do
      if WorkingHours.in_working_hours? Time.now
        CustomField.where(name: 'slack').first.tap do |slack_custom_field|
          Slack.token = 'xoxp-2367863251-2368652112-3225378160-241096'
          Marcel::Reminder::find_users_to_remind(Marcel::Reminder::ALERT_HARD).each do |report|
            Slack.chat_postMessage channel: '@' + (CustomValue.where(
                                                    custom_field_id: slack_custom_field.id,
                                                    customized_id: report[:user].id,
                                                   ).where("value != ''").first.value rescue report[:user].login),
              text: Marcel::Reminder::format_remind_message(report),
              username: 'Redminder'
          end
        end
      end
    end

    desc 'Remind all users to update their times (via email)'
    task mail: :environment do
    end

  end
end
