source "https://rubygems.org"

ruby "3.2.11"

gem "rails", "~> 7.1.5"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bcrypt", "~> 3.1.7"
gem "jwt", "~> 2.7"
gem "rack-cors"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]

  # Testing stack (RSpec + FactoryBot)
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "shoulda-matchers", "~> 6.0"
  gem "faker", "~> 3.2"
end

group :test do
  gem "simplecov", "~> 0.22", require: false
end
