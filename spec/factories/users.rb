FactoryBot.define do
  factory :user do
    sequence(:firstname) { |n| "firstname-#{n}" }
    sequence(:lastname) { |n| "lastname-#{n}" }
    sequence(:email) { |n| "email-#{n}@skello.io" }
    sequence(:password) { |n| "pwd-#{n}" }
    sequence(:password_confirmation) { |n| "pwd-#{n}" }
  end
end
