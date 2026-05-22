class CreditRule < ApplicationRecord
  belongs_to :user

  validates :spend_amount, presence: true, numericality: { greater_than: 0 }
  validates :credit_amount, presence: true, numericality: { greater_than: 0, only_integer: true }
end
