class Vacation < ActiveRecord::Base
  belongs_to :user
  belongs_to :validator, class_name: 'User'
  belongs_to :activity, class_name: 'TimeEntryActivity', foreign_key: 'activity_id'

  validates_presence_of :user
  validates_presence_of :activity
  validates_presence_of :from
  validates_presence_of :to

  def validable_by?(user)
    gid = Setting.plugin_marcel[:allowed_edit_group_id]
    return ((not gid.nil?) and user.is_or_belongs_to?(Group.where(id: gid).first))
  end

  def updatable_by?(user)
    return ((user.id == self.user_id and not self.validated?) or self.validable_by?(user))
  end

  def validate(status=true)
    ret = self.update_attributes status: status, validator_id: User.current.id
    if status
      # Create time entries
    else
      # self.time_entries.map do |t|
      #  t.delete
      # end
    end
    return ret
  end

  def validated?
    return self.status
  end

  def rejected?
    return (!self.status and self.validator.present?)
  end

end
