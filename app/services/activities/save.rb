module Activities
  class Save
    # Pass a new or unchanged persisted Activity and scalar attributes separately.
    # Omitted oshi_ids preserves existing links; [] explicitly requests no links.
    # Returns the saved Activity; failures raise and roll back all database changes.
    def self.call(activity:, attributes: {}, oshi_ids: nil)
      Activity.transaction do
        activity.lock! if activity.persisted?
        activity.activity_oshis.reload if activity.persisted?

        ids = if oshi_ids.nil?
          activity.activity_oshis.map(&:oshi_id)
        else
          oshi_ids.map { |id| Oshi.type_for_attribute("id").cast(id) }.uniq
        end

        activity.assign_attributes(attributes)
        if ids.empty?
          activity.errors.add(:activity_oshis, "must include at least one oshi")
          raise ActiveRecord::RecordInvalid, activity
        end

        existing_ids = activity.activity_oshis.map(&:oshi_id)
        (ids - existing_ids).each { |id| activity.activity_oshis.build(oshi_id: id) }
        activity.save!
        ids = activity.activity_oshis.reject(&:destroyed?).map(&:oshi_id) if oshi_ids.nil?

        # Additions have been saved before any removal, including A -> B changes.
        activity.activity_oshis.where.not(oshi_id: ids).each(&:destroy!)
        activity.activity_oshis.reload
        unless activity.activity_oshis.exists?
          activity.errors.add(:activity_oshis, "must include at least one oshi")
          raise ActiveRecord::RecordInvalid, activity
        end

        activity
      end
    end
  end
end
