class Customer < ApplicationRecord
  belongs_to :user

  has_many :sales, dependent: :destroy
  has_one :customer_credit, dependent: :destroy

  validates :name, presence: true
  validates :birth_date, presence: true
  validates :phone_number, presence: true
  validates :cpf, presence: true, uniqueness: { scope: :user_id }

  after_create :create_credit_balance

  private

  def create_credit_balance
    create_customer_credit!(available_credits: 0)
  end
end
