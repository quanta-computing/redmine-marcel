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

  def validate(status=true)
    return self.update_attributes status: status, validator_id: User.current.id
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
