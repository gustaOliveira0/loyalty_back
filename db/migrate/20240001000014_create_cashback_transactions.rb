class CreateCashbackTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :cashback_transactions do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :sale,     foreign_key: true
      t.references :sale_item, foreign_key: true
      # earn (positivo) / redeem (negativo) / expire (negativo) / adjust (qualquer)
      t.string  :kind,   null: false
      t.string  :unit,   null: false # "money" ou "points" no momento do lançamento
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.datetime :expires_at # apenas para kind=earn
      t.string  :description
      t.timestamps
    end

    add_index :cashback_transactions, [:customer_id, :kind]
    add_index :cashback_transactions, :expires_at
  end
end
