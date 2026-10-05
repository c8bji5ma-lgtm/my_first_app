class ActivityOshi < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_oshis
  belongs_to :oshi

  validates :oshi_id, uniqueness: { scope: :activity_id }

  before_destroy :preserve_at_least_one_oshi

  private

    def preserve_at_least_one_oshi
      return unless persisted?

      # destroy runs in a transaction, so this lock remains held through deletion.
      parent = Activity.lock.find(activity_id_in_database)
      return if parent.activity_oshis.where.not(id: id).exists?

      errors.add(:base, "Activity must retain at least one oshi")
      throw :abort
    end
end
