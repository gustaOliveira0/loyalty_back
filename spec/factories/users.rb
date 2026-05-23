FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Loja #{n}" }
    sequence(:email) { |n| "loja#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
