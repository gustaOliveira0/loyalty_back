FactoryBot.define do
  factory :collaborator do
    association :user
    sequence(:name) { |n| "Colaborador #{n}" }
    sequence(:cpf) { |n| "#{n.to_s.rjust(11, '0')}" }
    birth_date { "1990-01-01" }
    sequence(:email) { |n| "colaborador#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    active { true }

    can_edit_customers      { true }
    can_delete_customers    { true }
    can_create_sales        { true }
    can_manage_products     { true }
    can_manage_categories   { true }
    can_manage_credit_rules { true }
    can_view_dashboard      { true }
    can_manage_settings     { false }

    trait :inactive do
      active { false }
    end

    trait :restricted do
      can_edit_customers      { false }
      can_delete_customers    { false }
      can_create_sales        { false }
      can_manage_products     { false }
      can_manage_categories   { false }
      can_manage_credit_rules { false }
      can_view_dashboard      { false }
      can_manage_settings     { false }
    end
  end
end
