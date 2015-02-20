require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'

namespace :marcel do

  desc 'Update the google calendar API according to vacations'
  task update_gcal: :environment do
    Marcel::Gcal::connection do |client, auth|
      client.discovered_api('calendar', 'v3').tap do |calendar|
        Vacation.gcal_update_needed.each do |vacation|
          Marcel::Gcal.send "#{vacation.gcal_event_id.nil? ? 'create' : 'delete'}_vacation_event",
              client, auth, vacation, calendar
        end
      end
    end
  end

end
