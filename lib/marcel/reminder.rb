module Marcel
  module Reminder
    MIN_LOGGED_HOURS = 5.0

    ALERT_OFF = 0
    ALERT_SOFT = 1
    ALERT_HARD = 2
    REMIND_LEVEL_SELECT_OPTS = [
      ['Off', ALERT_OFF],
      ['Soft notify (email)', ALERT_SOFT],
      ['Hard notify (email + slack)', ALERT_HARD],
    ]

    def self.find_users_to_remind(remind_level=ALERT_HARD, min_time=MIN_LOGGED_HOURS, time=Time.now)
      User.where("time_remind_level >= #{remind_level}").select(&:active?).map do |user|
        last_worked_day = Marcel::last_worked_day(user, time)
        {
          user: user,
          last_worked_day: last_worked_day,
          hours: TimeEntry.where(user_id: user.id, spent_on: last_worked_day.to_date).to_a.sum(&:hours),
        }
      end.select{|u| u[:hours] < min_time}
    end

    def self.format_remind_message(remind)
        [
          "Hello #{remind[:user].firstname},",
          "",
          "You logged only #{remind[:hours]} hours on #{remind[:last_worked_day].to_date}... :(",
          "Please update your time entries on https://redmine.quanta.gr ! :3",
        ].join("\n")
    end

  end
end
