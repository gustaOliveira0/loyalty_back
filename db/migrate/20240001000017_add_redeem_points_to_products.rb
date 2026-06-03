class AddRedeemPointsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :redeem_points, :decimal, precision: 12, scale: 2, default: 0, null: false
  end
end
