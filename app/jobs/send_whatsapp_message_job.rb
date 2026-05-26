class SendWhatsappMessageJob < ApplicationJob
  queue_as :whatsapp

  # Retentativa em falhas de rede; falhas permanentes são marcadas como failed.
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(customer_id, template_key, vars = {})
    customer = Customer.find_by(id: customer_id)
    return unless customer
    return unless customer.whatsapp_opt_in

    store = customer.user
    vars = vars.symbolize_keys.merge(
      customer_name: customer.name.split.first,
      store_name:    store.name
    )

    body = Whatsapp::Templates.render(template_key, vars)

    delivery = customer.message_deliveries.create!(
      channel: "whatsapp", template: template_key,
      status: "queued", body: body
    )

    result = Whatsapp::Adapter.current.send_message(phone: customer.phone_number, body: body)

    if result[:ok]
      delivery.update!(status: "sent", sent_at: Time.current,
                       provider_message_id: result[:provider_message_id])
    else
      delivery.update!(status: "failed", error: result[:error])
      raise result[:error].to_s
    end
  end
end
