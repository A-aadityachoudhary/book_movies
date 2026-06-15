class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :showtime
  has_many :tickets, dependent: :destroy
  has_many :showtime_seats, through: :tickets

  # 0 means created but not paid, 1 means paid successfully, 2 means payment failed.
  enum :status, { pending: 0, paid: 1, failed: 2 }
end