class Sale < ApplicationRecord
  belongs_to :user
  belongs_to :customer

  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :sale_date, presence: true

  after_create :apply_credits

  private

  def apply_credits
    rule = user.credit_rules.order(spend_amount: :desc).first
    return unless rule

    credits_earned = (total / rule.spend_amount).floor * rule.credit_amount
    return if credits_earned <= 0

    credit = customer.customer_credit || customer.create_customer_credit!(available_credits: 0)
    credit.increment!(:available_credits, credits_earned)
  end
end
