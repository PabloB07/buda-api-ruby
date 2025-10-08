require 'bundler/setup'
require 'buda_api'
require 'webmock/rspec'
require 'vcr'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Configure WebMock
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

# Configure VCR for HTTP request recording/playback
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV['BUDA_API_KEY'] }
  config.filter_sensitive_data('<API_SECRET>') { ENV['BUDA_API_SECRET'] }
  config.filter_sensitive_data('<SIGNATURE>') do |interaction|
    interaction.request.headers['X-SBTC-SIGNATURE']&.first
  end
  config.filter_sensitive_data('<NONCE>') do |interaction|
    interaction.request.headers['X-SBTC-NONCE']&.first
  end
end