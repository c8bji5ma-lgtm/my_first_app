FactoryBot.define do
  factory :oshi_alias do
    oshi
    sequence(:alias_name) { |n| "別名#{n}" }
  end
end
