namespace :marcel do
  namespace :reminder do

    desc 'Remind all users to update their times (via slack)'
    task slack: :environment do
      slack_username_field = CustomField.where(name: 'slack').first
      Marcel::Reminder::find_users_to_remind(Marcel::Reminder::ALERT_HARD).each do |report|
        Marcel::Slacker.send_message(
          report[:user], Marcel::Reminder::format_remind_message(report),
          slack_username_field) if Marcel::is_working? report[:user]
      end
    end

    desc 'Remind all users to update their times (via email)'
    task mail: :environment do
    end

  end
end
