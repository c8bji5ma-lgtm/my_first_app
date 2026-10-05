FactoryBot.define do
  factory :subscription do
    user
    sequence(:name) { |n| "契約#{n}" }
    amount { 1000 }
    billing_cycle { "monthly" }
    started_on { nil }
    ended_on { nil }

    trait :yearly do
      billing_cycle { "yearly" }
    end
  end
end
