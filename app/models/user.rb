class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable

  validates :admin, inclusion: { in: [ true, false ] }
end
