
module Marcel

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
    vacations = Vacation.where(user_id: user.id, status: true).to_a
    begin
      day -= 1.days
    end while Holidays.on(day, :fr).any? or
              vacations.any?{ |v| day >= v.from and day <= v.to } or
              not WorkingHours.working_day? day
    return day
  end

  def self.holidays(from, to)
    Holidays.between(from, to, :fr).map { |h| h[:date] }
  end

end
