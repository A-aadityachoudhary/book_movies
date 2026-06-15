class Ability
  include CanCan::Ability

  def initialize(user)
    # If a user is not logged in, treat them as a guest
    user ||= User.new 

    if user.admin?
      # Admins can manage EVERYTHING (Create movies, add showtimes, view statistics)
      can :manage, :all
    elsif user.customer?
      # Customers can view movies and showtimes, and manage their own bookings
      can :read, Movie
      can :read, Showtime
      can [:read, :create], Booking, user_id: user.id
    else
      # Guests (not logged in) can only browse movies and showtimes
      can :read, Movie
      can :read, Showtime
    end
  end
end