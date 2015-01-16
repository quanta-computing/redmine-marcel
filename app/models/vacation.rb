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
    unless self.to > self.from
      self.errors.add :to, 'Ending date must be greater than beginning date'
    end
  end

  def validable_by?(user)
    gid = Setting.plugin_marcel[:allowed_edit_group_id]
    return ((not gid.nil?) and user.is_or_belongs_to?(Group.where(id: gid).first))
  end

  def updatable_by?(user)
    return ((user.id == self.user_id and not self.validated?) or self.validable_by?(user))
  end

  def days
    return (self.to.to_date - self.from.to_date).to_i
  end

  def validate(status=true)
    if (status != self.status)
      pv_days = self.activity.use_paid_vacation_days ? self.days : 0
      recup_days = self.activity.use_recup_days ? self.days : 0
      self.user.paid_vacation_days += pv_days * (status ? -1 : 1)
      self.user.recup_days += recup_days * (status ? -1 : 1)
    end
    return (self.user.save and self.update_attributes status: status, validator_id: User.current.id)
  end

  def validated?
    return self.status
  end

  def rejected?
    return (!self.status and self.validator.present?)
  end

  def activity
    return (super or VacationType.none)
  end

end
