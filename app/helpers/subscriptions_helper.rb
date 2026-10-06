module SubscriptionsHelper
  def billing_cycle_label(cycle)
    { "monthly" => "月額", "yearly" => "年額" }.fetch(cycle)
  end
end
