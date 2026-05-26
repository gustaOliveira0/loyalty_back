class AddCashbackFieldsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :cashback_mode, :string, null: false, default: "percent"
    add_column :products, :cashback_value, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
