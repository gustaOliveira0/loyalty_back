class Collaborator < ApplicationRecord
  belongs_to :user
  has_secure_password

  encrypts :cpf, deterministic: true

  PERMISSION_FLAGS = %i[
    can_edit_customers
    can_delete_customers
    can_create_sales
    can_manage_products
    can_manage_categories
    can_manage_credit_rules
    can_view_dashboard
    can_manage_settings
  ].freeze

  scope :active, -> { where(active: true) }

  validates :name, presence: true
  validates :birth_date, presence: true
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :cpf, presence: true, uniqueness: { scope: :user_id, message: "já cadastrado nesta loja" }

  def can?(permission)
    self.class.column_names.include?(permission.to_s) && self[permission] == true
  end
end
