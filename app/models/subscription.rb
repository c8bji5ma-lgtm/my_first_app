class Subscription < ApplicationRecord
  belongs_to :user
  has_many :subscription_oshis
  has_many :oshis, through: :subscription_oshis

  enum :billing_cycle, {
    monthly: "monthly", yearly: "yearly"
  }, validate: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
