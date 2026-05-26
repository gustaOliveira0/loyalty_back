class User < ApplicationRecord
  has_secure_password

  has_many :customers, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :credit_rules, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :products, dependent: :destroy

  CASHBACK_KINDS = %w[money points].freeze

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :cashback_kind, inclusion: { in: CASHBACK_KINDS }
  validates :cashback_expires_in_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :cashback_min_redeem, numericality: { greater_than_or_equal_to: 0 }

  def cashback_unit_label
    cashback_kind == "money" ? "R$" : "pts"
  end
end
