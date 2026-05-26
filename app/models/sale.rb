class Sale < ApplicationRecord
  belongs_to :user
  belongs_to :customer

  has_many :sale_items, dependent: :destroy
  has_many :cashback_transactions, dependent: :nullify
  accepts_nested_attributes_for :sale_items

  validates :total, presence: true, numericality: { greater_than: 0 }
  validates :sale_date, presence: true
end
