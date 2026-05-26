class AddCashbackSettingsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :cashback_kind, :string, null: false, default: "points"
    add_column :users, :cashback_expires_in_days, :integer, null: false, default: 30
    add_column :users, :cashback_min_redeem, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
