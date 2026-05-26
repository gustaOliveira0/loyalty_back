class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  validates :quantity,   numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :cashback_mode, inclusion: { in: Product::CASHBACK_MODES }

  def subtotal
    unit_price.to_d * quantity
  end
end
