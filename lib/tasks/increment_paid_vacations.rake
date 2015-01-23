namespace :marcel do

  desc "Updates paid vacation counters for all users (to be run once a month)"
  task increment_paid_vacations: :environment do
    User.safe_attributes 'paid_vacation_days'
    User.all.to_a.select(&:active?).each do |user|
      user.paid_vacation_days += Marcel::PAID_VACATION_DAYS_INCREMENT
      user.save
    end
  end

end
