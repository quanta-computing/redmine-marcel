
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
  after_create :notify_marcel_admins

  # Gcal events are created asynchronously via Rake
  scope :gcal_update_needed, -> do
    self.where %q{(gcal_event_id IS NULL AND status = 1)
                  OR (gcal_event_id IS NOT NULL AND status = 0)}
  end

  scope :between, lambda { |from, to|
    self.where("`from` >= ?", from + from.gmtoff).where("`to` <= ?", to + to.gmtoff)
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
    (2.0 * Marcel::working_days_between(self.from, self.to)).ceil / 2.0
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
    Marcel::Slacker.send_message self.user, self.format_validation_message
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

  def create_or_update
    if self.to.month != self.from.month
      self.dup.tap do |new_vacation|
        self.to = self.from.end_of_month
        new_vacation.from = (self.to + 1.month).beginning_of_month
        new_vacation.save!
      end
    end
    super
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

  def format_validation_message
    "Hi #{self.user.name} !\nYour vacation ##{self.id} (#{self.activity.name
    } between #{self.from} and #{self.to}) has been #{
    self.validated? ? 'validated' : 'rejected'} by #{self.validator.name}"
  end

  def format_pending_validation_message
    "Hi!\n#{self.user.name} asked for some #{self.activity.name} from #{self.from} to #{self.to
    }\nWould you mind checking this at https://redmine.quanta.gr/vacations/#{self.id} ?"
  end

  def activity
    super or VacationType.none
  end

  def user
    super or User.anonymous
  end

  def notify_marcel_admins
    Marcel::Slacker.send_message User.in_group(Setting.plugin_marcel[:allowed_edit_group_id]).to_a,
      self.format_pending_validation_message
  end

  def self.report from, to, users=nil, vacation_types=nil
    users ||= User.status(User::STATUS_ACTIVE).to_a
    vacation_types ||= VacationType.all.to_a

    vacations = Vacation.of_users(users).validated.between(from, to).includes(:activity)

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
