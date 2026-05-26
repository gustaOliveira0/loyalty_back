class AddWhatsappOptInToCustomers < ActiveRecord::Migration[7.1]
  def change
    # Default true: ao consentir com a LGPD na inscrição via QR, o cliente também
    # consente em receber avisos de cashback. Pode ser desligado depois.
    add_column :customers, :whatsapp_opt_in, :boolean, null: false, default: true
  end
end
