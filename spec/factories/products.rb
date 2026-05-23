FactoryBot.define do
  factory :product do
    association :category
    # Keep product and its category under the same store (user).
    user { category.user }
    sequence(:name) { |n| "Produto #{n}" }
    value { 9.99 }
    description { "Descrição do produto" }
  end
end
