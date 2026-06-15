class Screen < ApplicationRecord
  belongs_to :theater
  has_many :seats, dependent: :destroy
  has_many :showtimes, dependent: :destroy
end
