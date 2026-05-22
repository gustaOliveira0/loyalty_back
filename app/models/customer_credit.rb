class CustomerCredit < ApplicationRecord
  belongs_to :customer

  validates :available_credits, numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
