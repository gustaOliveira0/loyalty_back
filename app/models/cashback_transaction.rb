class CashbackTransaction < ApplicationRecord
  belongs_to :customer
  belongs_to :sale,      optional: true
  belongs_to :sale_item, optional: true

  KINDS = %w[earn redeem expire adjust].freeze
  UNITS = %w[money points].freeze

  validates :kind,   inclusion: { in: KINDS }
  validates :unit,   inclusion: { in: UNITS }
  validates :amount, numericality: true

  scope :earned,   -> { where(kind: "earn") }
  scope :redeemed, -> { where(kind: "redeem") }
  scope :expired,  -> { where(kind: "expire") }
  scope :active,   -> { where(kind: "earn").where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expiring_within, ->(days) {
    earned.where("expires_at IS NOT NULL AND expires_at BETWEEN ? AND ?",
                 Time.current, Time.current + days.to_i.days)
  }
end
