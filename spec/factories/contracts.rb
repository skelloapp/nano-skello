FactoryBot.define do
  factory :contract do
    user
    shop
    hourly_wage { 10 }
  end
end
