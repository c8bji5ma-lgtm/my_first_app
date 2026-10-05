class UserOshi < ApplicationRecord
  PERIOD_FORMAT = /\A[0-9]{4}(?:\/(?:0[1-9]|1[0-2]))?\z/

  belongs_to :user
  belongs_to :oshi

  before_validation :normalize_empty_periods

  validates :oshi_id, uniqueness: { scope: :user_id }
  validates :started_period, :ended_period,
    format: { with: PERIOD_FORMAT }, allow_nil: true

  private

    def normalize_empty_periods
      self.started_period = nil if started_period == ""
      self.ended_period = nil if ended_period == ""
    end
end
