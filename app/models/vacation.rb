
class Vacation < ActiveRecord::Base

  belongs_to :user
  belongs_to :validator, class_name: 'User'
  belongs_to :activity, class_name: 'VacationType', foreign_key: 'activity_id'


  validates_presence_of :user
  validates_presence_of :activity
  validates_presence_of :from
  validates_presence_of :to
  validate :to_greater_than_from


  def to_greater_than_from
    if self.to.present? and self.from.present? and self.to <= self.from
      self.errors.add :to, 'Ending date must be greater than beginning date'
    end
  end

  def validable_by?(user)
    Marcel::is_admin? user
  end

  def deletable_by?(user)
    (user.id == self.user_id and not self.validated?) or self.validable_by? user
  end

  def updatable_by?(user)
    self.validable_by?(user) and not self.validated?
  end

  def days
    WorkingHours::Config.holidays = Marcel::holidays(self.from.to_date - 1, self.to.to_date + 1)
    days = WorkingHours.working_time_between(self.from, self.to) / Marcel::SECONDS_IN_DAY
    return (2 * days).ceil / 2.0
  end

  def paid_vacation_days
    self.activity.use_paid_vacation_days ? self.days : 0
  end

  def recup_days
    self.activity.use_recup_days ? self.days : 0
  end

  def validate(status=true)
    if (status != self.status)
      self.user.paid_vacation_days += self.paid_vacation_days * (status ? -1 : 1)
      self.user.recup_days += self.recup_days * (status ? -1 : 1)
    end
    return (self.user.save and self.update_attributes status: status, validator_id: User.current.id)
  end

  def validated?
    self.status
  end

  def rejected?
    !self.status and self.validator.present?
  end

  def activity
    super or VacationType.none
  end

end
