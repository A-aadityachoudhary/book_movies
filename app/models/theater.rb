class Theater < ApplicationRecord
    has_many :screens, dependent: :destroy
end
