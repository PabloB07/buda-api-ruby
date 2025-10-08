# frozen_string_literal: true

require_relative "buda_api/version"
require_relative "buda_api/client"
require_relative "buda_api/public_client"
require_relative "buda_api/authenticated_client"
require_relative "buda_api/models"
require_relative "buda_api/constants"
require_relative "buda_api/errors"
require_relative "buda_api/logger"

# AI-enhanced features (optional)
begin
  require "ruby_llm"
  require_relative "buda_api/ai/trading_assistant"
  require_relative "buda_api/ai/natural_language_trader"
  require_relative "buda_api/ai/risk_manager"
  require_relative "buda_api/ai/report_generator"
  require_relative "buda_api/ai/anomaly_detector"
rescue LoadError
  # RubyLLM not available, AI features disabled
end

# BudaApi is the main module for the Buda.com API Ruby SDK
#
# This SDK provides comprehensive access to the Buda.com cryptocurrency exchange API
# with built-in error handling, debugging capabilities, and extensive examples.
#
# @example Basic usage with public API
#   client = BudaApi::PublicClient.new
#   markets = client.markets
#   ticker = client.ticker("BTC-CLP")
#
# @example Authenticated API usage
#   client = BudaApi::AuthenticatedClient.new(api_key: "your_key", api_secret: "your_secret")
#   balance = client.balance("BTC")
#   order = client.place_order("BTC-CLP", "ask", "limit", 1000000, 0.001)
#
module BudaApi
  class Error < StandardError; end

  # Configure the SDK with global settings
  class Configuration
    attr_accessor :base_url, :timeout, :retries, :debug_mode, :logger_level

    def initialize
      @base_url = "https://www.buda.com/api/v2/"
      @timeout = 30
      @retries = 3
      @debug_mode = false
      @logger_level = :info
    end
  end

  class << self
    attr_accessor :configuration
  end

  # Configure the SDK
  # 
  # @yield [Configuration] configuration object
  # @example
  #   BudaApi.configure do |config|
  #     config.debug_mode = true
  #     config.timeout = 60
  #   end
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # Get current configuration
  # @return [Configuration] current configuration
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Convenience method to create a public client
  # @param options [Hash] client options
  # @return [PublicClient] new public client instance
  def self.public_client(options = {})
    PublicClient.new(options)
  end

  # Convenience method to create an authenticated client
  # @param api_key [String] API key
  # @param api_secret [String] API secret
  # @param options [Hash] additional client options
  # @return [AuthenticatedClient] new authenticated client instance
  def self.authenticated_client(api_key:, api_secret:, **options)
    AuthenticatedClient.new(api_key: api_key, api_secret: api_secret, **options)
  end

  # Check if AI features are available
  # @return [Boolean] true if RubyLLM is available
  def self.ai_available?
    defined?(RubyLLM) && defined?(BudaApi::AI)
  end

  # Convenience method to create an AI-enhanced trading assistant
  # @param client [AuthenticatedClient] authenticated client
  # @param llm_provider [Symbol] LLM provider (:openai, :anthropic, etc.)
  # @return [AI::TradingAssistant] new trading assistant instance
  def self.trading_assistant(client, llm_provider: :openai)
    raise Error, "AI features not available. Install ruby_llm gem." unless ai_available?
    
    AI::TradingAssistant.new(client, llm_provider: llm_provider)
  end

  # Convenience method to create a natural language trader
  # @param client [AuthenticatedClient] authenticated client
  # @return [AI::NaturalLanguageTrader] new natural language trader instance
  def self.natural_language_trader(client)
    raise Error, "AI features not available. Install ruby_llm gem." unless ai_available?
    
    AI::NaturalLanguageTrader.new(client)
  end
end