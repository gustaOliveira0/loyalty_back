FactoryBot.define do
  factory :credit_rule do
    association :user
    spend_amount { 100.00 }
    credit_amount { 10 }
  end
end
