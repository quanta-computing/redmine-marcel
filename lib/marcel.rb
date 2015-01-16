
module Marcel

  def self.is_admin?(user)
    gid = Setting.plugin_marcel[:allowed_edit_group_id]
    return ((not gid.nil?) and user.is_or_belongs_to?(Group.where(id: gid).first))
  end

  def self.holidays(from, to)
    Holidays.between(from, to, :fr).map { |h| h[:date] }
  end

  def self.time_zone
    'Paris'
  end

  def self.working_hours
    {
      :mon => {'10:00' => '12:00', '13:00' => '19:00'},
      :tue => {'10:00' => '12:00', '13:00' => '19:00'},
      :wed => {'10:00' => '12:00', '13:00' => '19:00'},
      :thu => {'10:00' => '12:00', '13:00' => '19:00'},
      :fri => {'10:00' => '12:00', '13:00' => '19:00'},
    }
  end

  def self.hours_in_day
    return 8.0
  end

  def self.seconds_in_day
    return 3600 * self.hours_in_day
  end

end
