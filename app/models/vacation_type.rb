class VacationType < ActiveRecord::Base
  validates_presence_of :name

  def to_s
    return self.name
  end

  def self.manageable_by?(user)
    gid = Setting.plugin_marcel[:allowed_edit_group_id]
    return ((not gid.nil?) and user.is_or_belongs_to?(Group.where(id: gid).first))
  end

  def self.none
    return self.new name: 'Unknown'
  end

end
