class SubscriptionOshi < ApplicationRecord
  belongs_to :subscription
  belongs_to :oshi

  validates :oshi_id, uniqueness: { scope: :subscription_id }
end
