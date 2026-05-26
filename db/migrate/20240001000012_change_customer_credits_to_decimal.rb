class ChangeCustomerCreditsToDecimal < ActiveRecord::Migration[7.1]
  def up
    change_column :customer_credits, :available_credits, :decimal, precision: 12, scale: 2, default: 0, null: false
  end

  def down
    change_column :customer_credits, :available_credits, :integer, default: 0, null: false
  end
end
