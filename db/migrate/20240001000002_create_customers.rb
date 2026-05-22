class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.date :birth_date, null: false
      t.string :phone_number, null: false
      t.string :cpf, null: true

      t.timestamps
    end

    add_index :customers, [:user_id, :cpf], unique: true
  end
end
