class CreateCollaborators < ActiveRecord::Migration[7.1]
  def change
    create_table :collaborators do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :cpf
      t.date :birth_date, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :active, default: true, null: false

      # Permission flags
      t.boolean :can_edit_customers,       default: true,  null: false
      t.boolean :can_delete_customers,     default: true,  null: false
      t.boolean :can_create_sales,         default: true,  null: false
      t.boolean :can_manage_products,      default: true,  null: false
      t.boolean :can_manage_categories,    default: true,  null: false
      t.boolean :can_manage_credit_rules,  default: true,  null: false
      t.boolean :can_view_dashboard,       default: true,  null: false
      t.boolean :can_manage_settings,      default: false, null: false

      t.timestamps
    end

    add_index :collaborators, :email, unique: true
    add_index :collaborators, [:user_id, :cpf], unique: true
  end
end
