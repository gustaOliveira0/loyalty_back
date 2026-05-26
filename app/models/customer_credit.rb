class CustomerCredit < ApplicationRecord
  belongs_to :customer

  # Cache do saldo derivado de CashbackTransaction. O ledger é a fonte da verdade.
  validates :available_credits, numericality: { greater_than_or_equal_to: 0 }

  def self.refresh_for!(customer)
    record = customer.customer_credit || customer.create_customer_credit!(available_credits: 0)
    record.update_column(:available_credits, customer.balance)
    record
  end
end
