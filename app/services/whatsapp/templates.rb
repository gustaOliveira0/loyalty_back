module Whatsapp
  module Templates
    # Mensagens em PT-BR. Cada chave aceita um hash de vars.
    TEMPLATES = {
      "cashback_received" => ->(v) {
        "Oi #{v[:customer_name]}! Você acabou de ganhar #{v[:amount]} de cashback em #{v[:store_name]}. " \
        "#{v[:expires_at] ? "Use até #{v[:expires_at].strftime("%d/%m/%Y")}." : ""}".strip
      },
      "cashback_expiring" => ->(v) {
        "Oi #{v[:customer_name]}, seu cashback de #{v[:amount]} em #{v[:store_name]} expira em " \
        "#{v[:expires_at].strftime("%d/%m/%Y")}. Aproveite antes que vença!"
      },
      "cashback_balance" => ->(v) {
        "Oi #{v[:customer_name]}, você tem #{v[:amount]} disponíveis em #{v[:store_name]}. Que tal aproveitar?"
      }
    }.freeze

    def self.render(key, vars)
      template = TEMPLATES[key.to_s] or raise ArgumentError, "template desconhecido: #{key}"
      template.call(vars)
    end
  end
end
