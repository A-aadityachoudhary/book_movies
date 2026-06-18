class ShowtimeSeat < ApplicationRecord
  belongs_to :showtime
  belongs_to :seat
  belongs_to :locked_by, class_name: 'User', optional: true

  enum :status, { available: 0, locked: 1, booked: 2 }

  # A helper to check if a lock has naturally expired
  def lock_expired?
    return true if locked_at.nil?
    Time.current > (locked_at + 5.minutes)
  end

  # Override availability check to account for expired time locks
  def truly_available?
    available? || (locked? && lock_expired?)
  end
end