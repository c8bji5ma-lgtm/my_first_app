class Subscription < ApplicationRecord
  belongs_to :user
  has_many :subscription_oshis
  has_many :oshis, through: :subscription_oshis

  enum :billing_cycle, {
    monthly: "monthly", yearly: "yearly"
  }, validate: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active_on, ->(date) {
    where("started_on IS NULL OR started_on <= ?", date)
      .where("ended_on IS NULL OR ended_on >= ?", date)
  }

  def active_on?(date = Date.current)
    (started_on.nil? || started_on <= date) && (ended_on.nil? || ended_on >= date)
  end
end
