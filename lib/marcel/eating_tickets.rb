module Marcel
  module EatingTickets

    def self.used_eating_tickets user, from, to, vacations=nil
      vacations ||= Vacation.of_user(user).between(from, to).includes(:activity)
      vacations.to_a.find_all{ |vacation| vacation.user_id == user.id }.sum &:eating_tickets
    end


    def self.available_eating_tickets from, to
      Marcel::working_days_between(from.beginning_of_day, to.end_of_day)
    end

    def self.user_eating_tickets user, from, to, vacations=nil
      self.available_eating_tickets(from, to) - self.used_eating_tickets(user, from, to, vacations)
    end

  end
end
