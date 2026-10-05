FactoryBot.define do
  factory :user_oshi do
    user
    oshi
    started_period { "2023" }
    ended_period { nil }
  end
end
