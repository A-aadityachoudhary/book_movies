class Showtime < ApplicationRecord
  belongs_to :movie
  belongs_to :screen
  has_many :showtime_seats, dependent: :destroy
  has_many :bookings, dependent: :destroy
end
