class Product < ApplicationRecord
  belongs_to :user
  belongs_to :category

  CASHBACK_MODES = %w[percent fixed].freeze

  validates :name, presence: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cashback_mode, inclusion: { in: CASHBACK_MODES }
  validates :cashback_value, numericality: { greater_than_or_equal_to: 0 }
  validate :percent_within_range

  # Cashback gerado por 1 unidade deste produto, na unidade da loja.
  def cashback_for(unit_price = value)
    case cashback_mode
    when "percent" then (unit_price.to_d * cashback_value.to_d / 100).round(2)
    when "fixed"   then cashback_value.to_d.round(2)
    else 0.to_d
    end
  end

  private

  def percent_within_range
    return unless cashback_mode == "percent"
    return if cashback_value.to_d.between?(0, 100)

    errors.add(:cashback_value, "percentual deve estar entre 0 e 100")
  end
end
