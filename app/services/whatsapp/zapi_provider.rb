require "net/http"
require "json"
require "uri"

module Whatsapp
  # Provider HTTP para Z-API ou compatível. Configurar via ENV:
  #   WHATSAPP_PROVIDER=zapi
  #   WHATSAPP_ZAPI_BASE=https://api.z-api.io/instances/<INSTANCE>/token/<TOKEN>
  #   WHATSAPP_ZAPI_CLIENT_TOKEN=<security token, header Client-Token>
  class ZapiProvider
    def send_message(phone:, body:)
      base = ENV["WHATSAPP_ZAPI_BASE"].to_s
      raise "WHATSAPP_ZAPI_BASE não configurado" if base.empty?

      uri = URI.parse("#{base.chomp("/")}/send-text")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 15

      req = Net::HTTP::Post.new(uri.request_uri, headers)
      req.body = { phone: normalize_phone(phone), message: body }.to_json
      res = http.request(req)

      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body) rescue {}
        { ok: true, provider_message_id: data["messageId"] || data["id"] }
      else
        { ok: false, error: "HTTP #{res.code}: #{res.body}" }
      end
    rescue => e
      { ok: false, error: e.message }
    end

    private

    def headers
      h = { "Content-Type" => "application/json" }
      token = ENV["WHATSAPP_ZAPI_CLIENT_TOKEN"]
      h["Client-Token"] = token if token.present?
      h
    end

    # Z-API espera DDI+DDD+numero sem caracteres especiais. Adiciona 55 (Brasil)
    # se vier apenas com DDD+numero.
    def normalize_phone(phone)
      digits = phone.to_s.gsub(/\D+/, "")
      digits.start_with?("55") ? digits : "55#{digits}"
    end
  end
end
