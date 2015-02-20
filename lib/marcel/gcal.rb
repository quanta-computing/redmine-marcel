require 'google/api_client'

module Marcel
  module Gcal

    def self.connection
      client = Google::APIClient.new application_name:'Redmine-marcel',
                  application_version: '1.0.0'
      auth = Signet::OAuth2::Client.new token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
              audience: 'https://accounts.google.com/o/oauth2/token',
              scope: 'https://www.googleapis.com/auth/calendar',
              issuer: Setting.plugin_marcel[:google_service_account_email],
              person: Setting.plugin_marcel[:google_user_email],
              signing_key: Google::APIClient::KeyUtils.load_from_pkcs12(
                            Setting.plugin_marcel[:google_key_file],
                            Setting.plugin_marcel[:google_key_passphrase])
      auth.fetch_access_token!
      yield client, auth
    end

    def self.calendar_connection
      Marcel::Gcal::connection do |client, auth|
        client.discovered_api('calendar', 'v3').tap do |api|
          yield client, auth, api
        end
      end
    end

    def self.create_vacation_event client, auth, vacation, api=nil
      Time::DATE_FORMATS[:rfc3389] = '%Y-%m-%dT%H:%M:%S'
      api ||= client.discovered_api 'calendar', 'v3'
      event = client.execute api_method: api.events.insert,
                parameters: {calendarId: Setting.plugin_marcel[:google_calendar_id]},
                body: JSON.dump({
                  summary: vacation.event_title,
                  description: vacation.event_description,
                  start: {
                    dateTime: vacation.from.to_formatted_s(:rfc3389),
                    timeZone: Marcel::TIMEZONE
                  },
                  end: {
                    dateTime: vacation.to.to_formatted_s(:rfc3389),
                    timeZone: Marcel::TIMEZONE
                  }
                }),
                headers: {'Content-Type' => 'application/json'},
                authorization: auth
      vacation.update_attributes gcal_event_id: event.data.id
      Rails.logger.info "Created gcal event #{event.data.id} for vacation #{vacation.id}"
    end

    def self.delete_vacation_event client, auth, vacation, api=nil
      api ||= client.discovered_api 'calendar', 'v3'
      response = client.execute api_method: api.events.delete,
                  parameters: {
                    calendarId: Setting.plugin_marcel[:google_calendar_id],
                    eventId: vacation.gcal_event_id
                  },
                  headers: {'Content-Type' => 'application/json'},
                  authorization: auth
      if response.body.empty?
        Rails.logger.info "Deleted gcal event #{vacation.gcal_event_id} for vacation #{vacation.id}"
        if not vacation.destroyed?
          vacation.update_attributes gcal_event_id: nil
        end
      else
        Rails.logger.error "Cannot delete event #{vacation.gcal_event_id}: #{response.body.error}"
      end
    end

  end
end
