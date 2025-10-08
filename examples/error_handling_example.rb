#!/usr/bin/env ruby
# frozen_string_literal: true

# Error handling and debugging example
#
# This example demonstrates comprehensive error handling and debugging features

require_relative "../lib/buda_api"

def main
  puts "=== Buda API Ruby SDK - Error Handling & Debugging Example ==="
  puts

  # Configure SDK with debug mode enabled
  BudaApi.configure do |config|
    config.debug_mode = true
    config.timeout = 10  # Short timeout to trigger timeout errors
    config.logger_level = :debug
  end

  # Example 1: Connection and timeout errors
  puts "1. Testing connection errors..."
  begin
    # Create client with invalid base URL
    client = BudaApi::PublicClient.new(base_url: "https://invalid-domain-that-does-not-exist.com/api/v2/")
    client.markets
  rescue BudaApi::ConnectionError => e
    puts "✅ Caught ConnectionError as expected: #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 2: Timeout errors
  puts "2. Testing timeout handling..."
  begin
    client = BudaApi::PublicClient.new(timeout: 0.001)  # Very short timeout
    client.markets
  rescue BudaApi::TimeoutError => e
    puts "✅ Caught TimeoutError as expected: #{e.message}"
  rescue BudaApi::ConnectionError => e
    puts "✅ Connection error (may occur instead of timeout): #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 3: Validation errors
  puts "3. Testing validation errors..."
  client = BudaApi::PublicClient.new

  begin
    # Test invalid market ID
    client.ticker("INVALID-MARKET")
  rescue BudaApi::ValidationError => e
    puts "✅ Caught ValidationError as expected: #{e.message}"
  rescue BudaApi::NotFoundError => e
    puts "✅ Caught NotFoundError (API-level validation): #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end

  begin
    # Test missing required parameters
    client.quotation(nil, "bid_given_size", 0.1)
  rescue BudaApi::ValidationError => e
    puts "✅ Caught ValidationError for missing parameter: #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 4: Authentication errors
  puts "4. Testing authentication errors..."
  begin
    auth_client = BudaApi::AuthenticatedClient.new(
      api_key: "invalid_key",
      api_secret: "invalid_secret"
    )
    auth_client.balance("BTC")
  rescue BudaApi::AuthenticationError => e
    puts "✅ Caught AuthenticationError as expected: #{e.message}"
    puts "   Status code: #{e.status_code}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 5: API response errors
  puts "5. Testing API response handling..."
  begin
    # Test with non-existent market (should return 404)
    client.ticker("FAKE-COIN")
  rescue BudaApi::NotFoundError => e
    puts "✅ Caught NotFoundError as expected: #{e.message}"
    puts "   Status code: #{e.status_code}"
    puts "   Response headers: #{e.response_headers.keys.join(', ')}" if e.response_headers
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 6: Rate limiting (simulated)
  puts "6. Testing rate limit handling..."
  puts "Making multiple rapid requests to potentially trigger rate limiting..."
  
  10.times do |i|
    begin
      client.ticker("BTC-CLP")
      print "."
    rescue BudaApi::RateLimitError => e
      puts "\n✅ Caught RateLimitError: #{e.message}"
      break
    rescue => e
      puts "\n❌ Unexpected error: #{e.class.name} - #{e.message}"
      break
    end
    
    # Small delay between requests
    sleep(0.1)
  end
  puts "\nCompleted rate limit test"
  puts

  # Example 7: Invalid credentials format
  puts "7. Testing credential validation..."
  begin
    BudaApi::AuthenticatedClient.new(api_key: "", api_secret: "secret")
  rescue BudaApi::ConfigurationError => e
    puts "✅ Caught ConfigurationError for empty API key: #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end

  begin
    BudaApi::AuthenticatedClient.new(api_key: "key", api_secret: nil)
  rescue BudaApi::ConfigurationError => e
    puts "✅ Caught ConfigurationError for nil API secret: #{e.message}"
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 8: Debugging successful requests
  puts "8. Demonstrating debug output for successful requests..."
  puts "Watch the detailed HTTP request/response logs above ☝️"
  
  begin
    markets = client.markets
    puts "✅ Successfully fetched #{markets.length} markets with debug logging"
    
    ticker = client.ticker("BTC-CLP")
    puts "✅ Successfully fetched ticker with debug logging"
    
  rescue => e
    puts "❌ Unexpected error: #{e.class.name} - #{e.message}"
  end
  puts

  # Example 9: Custom error context
  puts "9. Demonstrating error context and logging..."
  
  begin
    # Simulate a custom error scenario
    raise BudaApi::ValidationError, "Custom validation failed"
  rescue BudaApi::ValidationError => e
    BudaApi::Logger.log_error(e, context: { 
      user_action: "Testing custom error",
      market_id: "BTC-CLP",
      timestamp: Time.now 
    })
    puts "✅ Logged custom error with context"
  end
  puts

  # Example 10: Recovery strategies
  puts "10. Demonstrating error recovery strategies..."
  
  def retry_with_backoff(max_retries: 3, initial_delay: 1)
    retries = 0
    
    begin
      yield
    rescue BudaApi::RateLimitError, BudaApi::ServerError => e
      retries += 1
      
      if retries <= max_retries
        delay = initial_delay * (2 ** (retries - 1))
        puts "Retry #{retries}/#{max_retries} after #{delay}s due to: #{e.class.name}"
        sleep(delay)
        retry
      else
        puts "Max retries exceeded, giving up"
        raise
      end
    end
  end

  begin
    retry_with_backoff do
      # This might fail due to rate limiting or server errors
      client.markets
    end
    puts "✅ Request succeeded (possibly after retries)"
  rescue => e
    puts "❌ Request failed after retries: #{e.message}"
  end

  puts
  puts "=== Error Handling & Debugging Example Completed ==="
  puts
  puts "Key takeaways:"
  puts "- Always wrap API calls in appropriate exception handlers"
  puts "- Use debug mode during development to see detailed HTTP logs"
  puts "- Implement retry logic for transient errors (rate limits, server errors)"
  puts "- Validate parameters client-side before making API calls"
  puts "- Log errors with context for easier debugging"
  puts "- Different error types require different handling strategies"
end

main if __FILE__ == $0