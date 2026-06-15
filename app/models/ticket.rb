class Ticket < ApplicationRecord
  belongs_to :booking
  belongs_to :showtime_seat
end
