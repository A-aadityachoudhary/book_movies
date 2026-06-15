class ShowtimeSeat < ApplicationRecord
  belongs_to :showtime
  belongs_to :seat
  enum :status, { available: 0, locked: 1, booked: 2 }
end
