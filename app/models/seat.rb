class Seat < ApplicationRecord
  belongs_to :screen
  has_many :showtime_seats, dependent: :destroy
end
