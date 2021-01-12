FactoryBot.define do
  factory :shift do
    user
    shop
    starts_at { 2.hours.ago }
    ends_at { 1.hour.from_now }
    category { :work }

    trait :work do
      category { :work }
    end

    trait :paid_absence do
      category { :paid_absence }
    end

    trait :unpaid_absence do
      category { :unpaid_absence }
    end
  end
end
