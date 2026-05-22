class CreateCustomerCredits < ActiveRecord::Migration[7.1]
  def change
    create_table :customer_credits do |t|
      t.references :customer, null: false, foreign_key: true
      t.integer :available_credits, null: false, default: 0

      t.timestamps
    end
  end
end
