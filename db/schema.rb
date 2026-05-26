# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_00_01_000016) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cashback_transactions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "sale_id"
    t.bigint "sale_item_id"
    t.string "kind", null: false
    t.string "unit", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "expires_at"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "kind"], name: "index_cashback_transactions_on_customer_id_and_kind"
    t.index ["customer_id"], name: "index_cashback_transactions_on_customer_id"
    t.index ["expires_at"], name: "index_cashback_transactions_on_expires_at"
    t.index ["sale_id"], name: "index_cashback_transactions_on_sale_id"
    t.index ["sale_item_id"], name: "index_cashback_transactions_on_sale_item_id"
  end

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "credit_rules", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "spend_amount", precision: 10, scale: 2, null: false
    t.integer "credit_amount", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_credit_rules_on_user_id"
  end

  create_table "customer_credits", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.decimal "available_credits", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_customer_credits_on_customer_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.date "birth_date", null: false
    t.string "phone_number", null: false
    t.text "cpf"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "consented_at"
    t.string "consent_ip"
    t.string "consent_version"
    t.boolean "whatsapp_opt_in", default: true, null: false
    t.index ["user_id", "cpf"], name: "index_customers_on_user_id_and_cpf", unique: true
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "message_deliveries", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "channel", default: "whatsapp", null: false
    t.string "template", null: false
    t.string "status", default: "queued", null: false
    t.text "body"
    t.string "provider_message_id"
    t.text "error"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "template", "created_at"], name: "idx_msg_deliveries_customer_template_created"
    t.index ["customer_id"], name: "index_message_deliveries_on_customer_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "name", null: false
    t.decimal "value", precision: 10, scale: 2, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cashback_mode", default: "percent", null: false
    t.decimal "cashback_value", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["user_id"], name: "index_products_on_user_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.string "cashback_mode", default: "percent", null: false
    t.decimal "cashback_value", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "cashback_earned", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "customer_id", null: false
    t.decimal "total", precision: 10, scale: 2, null: false
    t.datetime "sale_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cashback_kind", default: "points", null: false
    t.integer "cashback_expires_in_days", default: 30, null: false
    t.decimal "cashback_min_redeem", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "cashback_transactions", "customers"
  add_foreign_key "cashback_transactions", "sale_items"
  add_foreign_key "cashback_transactions", "sales"
  add_foreign_key "categories", "users"
  add_foreign_key "credit_rules", "users"
  add_foreign_key "customer_credits", "customers"
  add_foreign_key "customers", "users"
  add_foreign_key "message_deliveries", "customers"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "users"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "users"
end
