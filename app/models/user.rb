class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { customer: 0, admin: 1 }
  has_many :bookings, dependent: :destroy
  before_validation :set_default_role, on: :create

  # 2. Helper methods to make role checking clean and intuitive
  def admin?
    role == 'admin'
  end

  def customer?
    role == 'customer'
  end

  private

  def set_default_role
    # If a role wasn't manually specified (like creating an admin via rails console), make them a customer
    self.role ||= 'customer'
  end
end
