FactoryBot.define do
  # Only used for isolated CustomerCredit validation specs (build, not create).
  # Creating one would conflict with the credit auto-created by Customer#after_create.
  factory :customer_credit do
    association :customer
    available_credits { 0 }
  end
end
