class CreateMessageDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :message_deliveries do |t|
      t.references :customer, null: false, foreign_key: true
      t.string  :channel,    null: false, default: "whatsapp"
      t.string  :template,   null: false
      t.string  :status,     null: false, default: "queued" # queued|sent|failed|skipped
      t.text    :body
      t.string  :provider_message_id
      t.text    :error
      t.datetime :sent_at
      t.timestamps
    end

    add_index :message_deliveries, [:customer_id, :template, :created_at],
              name: "idx_msg_deliveries_customer_template_created"
  end
end
