class OshiAlias < ApplicationRecord
  belongs_to :oshi

  validates :alias_name, presence: true, length: { maximum: 255 },
    uniqueness: { scope: :oshi_id }
end
