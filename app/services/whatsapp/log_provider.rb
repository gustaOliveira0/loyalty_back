module Whatsapp
  # Provider de desenvolvimento: imprime no log e retorna sucesso simulado.
  # Útil para validar todo o pipeline (job, fila, opt-in, template) sem gastar
  # crédito de WhatsApp.
  class LogProvider
    def send_message(phone:, body:)
      Rails.logger.info("[WHATSAPP:LOG] to=#{phone} body=#{body.inspect}")
      { ok: true, provider_message_id: "log-#{SecureRandom.hex(6)}" }
    end
  end
end
