class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  # Quando a venda é apagada, os SaleItems também são; aqui só liberamos a FK
  # para não bloquear a remoção. As CashbackTransactions associadas seguem o
  # dependent definido em Customer (destroy) ou Sale (nullify do sale_id).
  has_many :cashback_transactions, dependent: :nullify

  validates :quantity,   numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :cashback_mode, inclusion: { in: Product::CASHBACK_MODES }

  def subtotal
    unit_price.to_d * quantity
  end
end
