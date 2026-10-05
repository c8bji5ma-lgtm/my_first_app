FactoryBot.define do
  factory :activity do
    user
    occurred_on { Date.new(2026, 10, 1) }
    sequence(:title) { |n| "推し活#{n}" }
    activity_type { "ライブ・イベント" }
    amount { nil }

    transient do
      oshis_count { 1 }
    end

    after(:build) do |activity, evaluator|
      evaluator.oshis_count.times do
        activity.activity_oshis.build(oshi: build(:oshi))
      end
    end

    trait :without_oshis do
      oshis_count { 0 }
    end

    trait :multiple_oshis do
      oshis_count { 2 }
    end
  end
end
