class Profile < ApplicationRecord
  belongs_to :user

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :user_id, uniqueness: true
end
