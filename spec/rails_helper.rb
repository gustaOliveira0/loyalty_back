# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production.
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Load every Ruby file under spec/support (factories config, matchers, helpers).
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # FactoryBot short syntax: `create`, `build`, `attributes_for`, etc.
  config.include FactoryBot::Syntax::Methods

  # Helper that builds `Authorization: Bearer <jwt>` headers in request specs.
  config.include AuthHelper, type: :request

  # Each example runs inside a transaction that is rolled back afterwards.
  config.use_transactional_fixtures = true

  # Infer spec type from the directory (model/, request/, etc.).
  config.infer_spec_type_from_file_location!

  # Trim Rails framework lines from backtraces.
  config.filter_rails_from_backtrace!
end
