class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :value, precision: 10, scale: 2, null: false
      t.text :description

      t.timestamps
    end
  end
end
