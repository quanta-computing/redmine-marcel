
module Marcel

  TIMEZONE = 'Europe/Paris'

  HOURS_IN_DAY = 8
  SECONDS_IN_DAY = 3600 * HOURS_IN_DAY

  PAID_VACATION_DAYS_INCREMENT = 2.08

  WORKING_HOURS = {
      mon: {'10:00' => '12:00', '13:00' => '19:00'},
      tue: {'10:00' => '12:00', '13:00' => '19:00'},
      wed: {'10:00' => '12:00', '13:00' => '19:00'},
      thu: {'10:00' => '12:00', '13:00' => '19:00'},
      fri: {'10:00' => '12:00', '13:00' => '19:00'},
    }


  def self.is_admin?(user)
    gid = Setting.plugin_marcel[:allowed_edit_group_id]
    return ((not gid.nil?) and user.is_or_belongs_to?(Group.where(id: gid).first))
  end

  def self.last_worked_day(user, day=Time.now)
    day = Time.new day.year, day.month, day.day, 16 # We set the time to 15:00 to avoid infinite loop with is_working?
    Vacation.where(user_id: user.id, status: true).to_a.tap do |vacations|
      begin
        day -= 1.days
      end while not Marcel::is_working? user, day, vacations
      return day
    end
  end

  def self.is_working?(user, t=Time.now, vacations=nil)
    vacations ||= Vacation.where(user_id: user).where("? BETWEEN `from` AND `to`", t).to_a
    return ((not Holidays.on(t, :fr).any?) and
            (not vacations.any?{|v| v.from <= t and v.to >= t}) and
            WorkingHours.in_working_hours? t)
  end

  def self.holidays(from, to)
    Holidays.between(from, to, :fr).reduce([]) do |holidays, h|
      holidays << h[:date] if WorkingHours.working_day?(h[:date])
      holidays
    end
  end

  def self.working_days_between(from, to)
    WorkingHours.working_time_between(from, to) / Marcel::SECONDS_IN_DAY - Marcel::holidays(from, to).count
  end

end
