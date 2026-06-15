class Movie < ApplicationRecord
    has_many :showtimes, dependent: :destroy
end
