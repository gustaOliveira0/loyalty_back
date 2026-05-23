FactoryBot.define do
  factory :customer do
    association :user
    sequence(:name) { |n| "Cliente #{n}" }
    birth_date { Date.new(1990, 1, 1) }
    sequence(:phone_number) { |n| "1199999#{format('%04d', n % 10_000)}" }
    # 11-digit numeric CPF; uniqueness is scoped to user_id (no check-digit validation).
    sequence(:cpf) { |n| format("%011d", n) }

    # NOTE: Customer#after_create already creates a zeroed customer_credit,
    # so factories must never build a credit explicitly (would duplicate it).
  end
end
