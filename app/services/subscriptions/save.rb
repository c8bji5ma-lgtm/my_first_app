module Subscriptions
  class Save
    # Scalar attributes and link changes commit together; omitted IDs retain links.
    def self.call(subscription:, attributes: {}, oshi_ids: nil)
      Subscription.transaction do
        subscription.lock! if subscription.persisted?
        subscription.subscription_oshis.reload if subscription.persisted?
        existing_ids = subscription.subscription_oshis.map(&:oshi_id)
        ids = oshi_ids.nil? ? existing_ids : oshi_ids.map { |id| Oshi.type_for_attribute("id").cast(id) }.uniq

        subscription.assign_attributes(attributes)
        subscription.save!
        (ids - existing_ids).each { |id| subscription.subscription_oshis.create!(oshi_id: id) }
        subscription.subscription_oshis.where.not(oshi_id: ids).each(&:destroy!)
        subscription.subscription_oshis.reload
        subscription
      end
    end
  end
end
