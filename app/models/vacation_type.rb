class VacationType < ActiveRecord::Base
  validates_presence_of :name

  def to_s
    return self.name
  end

  def self.manageable_by?(user)
    Marcel::is_admin? user
  end

  def manageable_by?(user)
    self.class.manageable_by? user
  end

  def self.none
    return self.new name: 'Unknown', use_eating_tickets: false
  end

end
