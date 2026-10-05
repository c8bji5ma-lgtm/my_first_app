FactoryBot.define do
  factory :oshi do
    sequence(:name) { |n| "推し#{n}" }
    oshi_type { "アイドル" }

    trait :pending do
      status { "pending" }
    end

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
