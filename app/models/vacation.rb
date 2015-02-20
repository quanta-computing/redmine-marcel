
class Vacation < ActiveRecord::Base

  belongs_to :user
  belongs_to :validator, class_name: 'User'
  belongs_to :activity, class_name: 'VacationType', foreign_key: 'activity_id'


  validates_presence_of :user
  validates_presence_of :activity
  validates_presence_of :from
  validates_presence_of :to
  validate :to_greater_than_from

  after_destroy :delete_gcal_event

  scope :gcal_update_needed, -> do
    self.where %q{(gcal_event_id IS NULL AND status = 1)
                  OR (gcal_event_id IS NOT NULL AND status = 0)}
  end

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
    self.deletable_by?(user) and not self.validated?
  end

  def accountable_by?(user)
    self.validated? and self.validable_by? user
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
    ret = (self.user.save and self.update_attributes status: status, validator_id: User.current.id)
    if status and not self.gcal_event_id.present?
      self.create_gcal_event
    elsif self.gcal_event_id.present? and not status
      self.delete_gcal_event
    end
    return ret
  end

  def reject
    self.validate false
  end

  def update_gcal_event action
    Marcel::Gcal::connection do |client, auth|
      Marcel::Gcal.send "#{action}_vacation_event", client, auth, self
    end
  rescue Exception => e
    logger.error "Cannot #{action} gcal event #{self.gcal_event_id} for vacation #{self.id}: #{e.message}"
  end

  def create_gcal_event
    self.update_gcal_event :create
  end

  def delete_gcal_event
    if self.gcal_event_id.present?
      self.update_gcal_event :delete
    end
  end

  def validated?
    self.status
  end

  def rejected?
    !self.status and self.validator.present?
  end

  def accounted?
    self.accounted
  end

  def validator_name
    self.validator.present? ? self.validator.name : 'Unknown'
  end

  def event_title
    "#{self.user.name} - #{self.activity.name}"
  end

  def event_description
    "#{self.comment}\n\nValidated by: #{self.validator_name}"
  end

  def activity
    super or VacationType.none
  end

end
