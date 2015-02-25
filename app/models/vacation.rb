
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

  scope :between, lambda { |from, to|
    self.where("`from` >= ?", from).where("`to` <= ?", to)
  }

  scope :of_users, lambda { |users|
    self.where(user_id: users)
  }

  scope :validated, -> do
    self.where(status: true)
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
    days = (WorkingHours.working_time_between(self.from, self.to) / Marcel::SECONDS_IN_DAY) -
            Marcel::holidays(self.from.beginning_of_day, self.to.end_of_day).count
    p (2.0 * days).ceil / 2.0
  end

  def paid_vacation_days
    self.activity.use_paid_vacation_days ? self.days : 0
  end

  def recup_days
    self.activity.use_recup_days ? self.days : 0
  end


  def eating_tickets
    if not self.activity.use_eating_tickets?
      0
    else
      Marcel::working_days_between self.from.beginning_of_day, self.to.end_of_day
    end
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

  def self.report from, to, users=nil, vacation_types=nil
    users ||= User.status(User::STATUS_ACTIVE).to_a
    vacation_types ||= VacationType.all.to_a

    vacations = Vacation.validated.between(from, to).includes(:activity)

    users.reduce Hash.new do |reports, user|
      reports.merge user.id => {
        vacations: vacation_types.reduce({}){ |memo, type|
                      memo.merge type.id => { days: 0, eating_tickets: 0 }
                   },
        eating_tickets: Marcel::EatingTickets::user_eating_tickets(user, from, to, vacations)
      }
    end.tap do |reports|
      vacations.each do |vacation|
        {days: vacation.days, eating_tickets: vacation.eating_tickets}.tap do |values|
          reports[vacation.user_id][:vacations][vacation.activity_id].merge!(values) do |key, oldval, newval|
            oldval + newval
          end
        end
      end
    end
  end

end
