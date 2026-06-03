FactoryBot.define do
  factory :product do
    association :category
    # Keep product and its category under the same store (user).
    user { category.user }
    sequence(:name) { |n| "Produto #{n}" }
    value { 9.99 }
    description { "Descrição do produto" }
    cashback_mode  { "percent" }
    cashback_value { 0 }
    redeem_points  { 0 }
  end
end
