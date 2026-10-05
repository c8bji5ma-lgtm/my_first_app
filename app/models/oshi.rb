class Oshi < ApplicationRecord
  OSHI_TYPES = [
    "アイドル", "アーティスト", "俳優・タレント", "声優",
    "キャラクター", "スポーツ", "その他"
  ].freeze

  belongs_to :created_by_user, class_name: "User", optional: true
  has_many :oshi_aliases
  has_many :user_oshis
  has_many :users, through: :user_oshis
  has_many :subscription_oshis
  has_many :subscriptions, through: :subscription_oshis

  enum :status, {
    pending: "pending", approved: "approved", rejected: "rejected"
  }, validate: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :oshi_type, presence: true, length: { maximum: 50 },
    inclusion: { in: OSHI_TYPES }
  validates :affiliation, length: { maximum: 255 }
end
