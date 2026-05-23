FactoryBot.define do
  factory :sale do
    association :user
    # The customer must belong to the same store (user) as the sale.
    customer { association(:customer, user: user) }
    total { 100.00 }
    sale_date { Time.current }
  end
end
