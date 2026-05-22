class User < ApplicationRecord
  has_secure_password

  has_many :customers, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :credit_rules, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
end
