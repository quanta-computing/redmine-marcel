require 'slack'

module Marcel
  module Slacker

    SLACK_TOKEN = 'xoxp-2367863251-2368652112-3225378160-241096'
    BOT_NAME = 'Redminder'

    def self.slack_username_for user, custom_field=nil
      custom_field ||= CustomField.where(name: 'slack').first
      '@' + (CustomValue.where(
              custom_field_id: custom_field.id,
              customized_id: user.id,
              ).where("value != ''").first.value rescue user.login)
    end

    def self.send_message users, message, slack_custom_field=nil
      slack_custom_field ||= CustomField.where(name: 'slack').first
      Slack.token = SLACK_TOKEN
      Array.wrap(users).map do |user|
        self.slack_username_for user, slack_custom_field
      end.each do |channel|
        Rails.logger.info "Sending slack message to #{channel}"
        Slack.chat_postMessage channel: channel, text: message, username: BOT_NAME
      end
    end

  end
end
