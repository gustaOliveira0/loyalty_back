require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module LoyaltyBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # LGPD (Art. 46) — criptografia de dados pessoais em repouso.
    # O CPF é criptografado pelo Active Record Encryption (ver Customer#cpf).
    # Em PRODUÇÃO, defina as variáveis abaixo com chaves fortes geradas por
    # `bin/rails db:encryption:init` (ou armazene-as em credentials). Os valores
    # padrão servem APENAS para desenvolvimento/teste e não devem ir a produção.
    config.active_record.encryption.primary_key =
      ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "dev_only_primary_key_change_in_production_xx")
    config.active_record.encryption.deterministic_key =
      ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "dev_only_deterministic_key_change_in_prod_xx")
    config.active_record.encryption.key_derivation_salt =
      ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "dev_only_key_derivation_salt_change_in_prod_xx")
  end
end
