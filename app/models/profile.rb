class Profile < ApplicationRecord
  belongs_to :user

  has_one_attached :profile_image
  validates :profile_image, image_attachment: true

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :user_id, uniqueness: true
end
