module Whatsapp
  # Adapter factory — escolhe o provider via ENV.
  # WHATSAPP_PROVIDER=log (default) | zapi
  module Adapter
    def self.current
      case ENV.fetch("WHATSAPP_PROVIDER", "log")
      when "zapi" then ZapiProvider.new
      else LogProvider.new
      end
    end
  end
end
