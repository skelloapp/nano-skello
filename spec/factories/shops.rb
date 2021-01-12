FactoryBot.define do
  factory :shop do
    sequence(:name) { |n| "shop-#{n}" }
  end
end
