class CreateCreditRules < ActiveRecord::Migration[7.1]
  def change
    create_table :credit_rules do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :spend_amount, precision: 10, scale: 2, null: false
      t.integer :credit_amount, null: false

      t.timestamps
    end
  end
end
