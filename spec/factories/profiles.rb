FactoryBot.define do
  factory :profile do
    user
    sequence(:display_name) { |n| "利用者#{n}" }
    introduction { "推し活を記録しています。" }
  end
end
