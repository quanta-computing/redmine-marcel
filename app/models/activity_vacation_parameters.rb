class ActivityVacationParameters < ActiveRecord::Base
  belongs_to :activity, class_name: 'TimeEntryActivity'

  validates_presence_of :activity
end
