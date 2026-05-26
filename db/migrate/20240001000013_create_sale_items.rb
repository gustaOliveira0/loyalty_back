class CreateSaleItems < ActiveRecord::Migration[7.1]
  def change
    create_table :sale_items do |t|
      t.references :sale,    null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity,   null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      # Snapshot dos campos de cashback do produto no momento da venda — assim a
      # alteração de configuração posterior não retroage no histórico/extrato.
      t.string  :cashback_mode,   null: false, default: "percent"
      t.decimal :cashback_value,  precision: 10, scale: 2, null: false, default: 0
      t.decimal :cashback_earned, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
  end
end
