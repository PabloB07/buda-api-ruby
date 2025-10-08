#!/usr/bin/env ruby
# frozen_string_literal: true

# Authenticated API usage example
#
# This example shows how to use the authenticated API endpoints for trading

require_relative "../lib/buda_api"
require "dotenv/load"

def main
  puts "=== Buda API Ruby SDK - Authenticated API Example ==="
  puts

  # Load credentials from environment variables
  api_key = ENV["BUDA_API_KEY"]
  api_secret = ENV["BUDA_API_SECRET"]

  if api_key.nil? || api_secret.nil?
    puts "ERROR: Please set BUDA_API_KEY and BUDA_API_SECRET environment variables"
    puts "You can create a .env file with:"
    puts "BUDA_API_KEY=your_api_key_here"
    puts "BUDA_API_SECRET=your_api_secret_here"
    return
  end

  # Configure the SDK for testing (use staging environment if available)
  BudaApi.configure do |config|
    config.debug_mode = true
    config.timeout = 60
    # config.base_url = "https://staging.buda.com/api/v2/"  # Uncomment for staging
  end

  # Create an authenticated client
  client = BudaApi.authenticated_client(
    api_key: api_key,
    api_secret: api_secret
  )

  market_id = "BTC-CLP"

  begin
    # 1. Check account balances
    puts "1. Checking account balances..."
    
    ["BTC", "CLP"].each do |currency|
      balance = client.balance(currency)
      puts "#{currency} Balance:"
      puts "  Total: #{balance.amount}"
      puts "  Available: #{balance.available_amount}"
      puts "  Frozen: #{balance.frozen_amount}"
      puts "  Pending withdrawals: #{balance.pending_withdraw_amount}"
      puts
    end

    # 2. Get balance events
    puts "2. Getting recent balance events..."
    events_result = client.balance_events(
      currencies: ["BTC", "CLP"],
      event_names: ["transaction", "deposit_confirm"],
      page: 1,
      per_page: 5
    )
    
    puts "Total events: #{events_result[:total_count]}"
    puts "Events on this page: #{events_result[:events].length}"
    puts

    # 3. Get order history
    puts "3. Getting order history for #{market_id}..."
    orders_result = client.orders(market_id, page: 1, per_page: 10)
    
    puts "Orders found: #{orders_result.count}"
    puts "Current page: #{orders_result.meta.current_page}"
    puts "Total pages: #{orders_result.meta.total_pages}"
    
    if orders_result.count > 0
      puts "\nRecent orders:"
      orders_result.orders.first(3).each do |order|
        puts "  Order ##{order.id}: #{order.type} #{order.amount} at #{order.limit} (#{order.state})"
        puts "    Created: #{order.created_at}"
        puts "    Filled: #{order.filled_percentage}%"
      end
    end
    puts

    # 4. Get quotation before placing an order
    puts "4. Getting quotation for a small test order..."
    test_amount = 0.0001  # Very small amount for testing
    
    quotation = client.quotation(market_id, "bid_given_size", test_amount)
    puts "To buy #{test_amount} BTC:"
    puts "  You would pay: #{quotation.quote_balance_change}"
    puts "  Fee: #{quotation.fee}"
    puts

    # 5. Simulate a withdrawal
    puts "5. Simulating a BTC withdrawal..."
    begin
      withdrawal_sim = client.simulate_withdrawal("BTC", 0.001)
      puts "Withdrawal simulation:"
      puts "  Amount: #{withdrawal_sim.amount}"
      puts "  Fee: #{withdrawal_sim.fee}"
      puts "  Currency: #{withdrawal_sim.currency}"
      puts "  State: #{withdrawal_sim.state}"
    rescue BudaApi::ApiError => e
      puts "Could not simulate withdrawal: #{e.message}"
    end
    puts

    # 6. Place a very small test order (BE CAREFUL!)
    puts "6. DEMO: Placing a test order (this is for demonstration only)..."
    puts "WARNING: This would place an actual order on the exchange!"
    puts "Skipping order placement in this example for safety."
    
    # UNCOMMENT THE FOLLOWING LINES ONLY IF YOU WANT TO PLACE ACTUAL ORDERS:
    # 
    # begin
    #   # Place a limit buy order with a very low price (unlikely to fill)
    #   order = client.place_order(
    #     market_id, 
    #     "Bid",           # Buy order
    #     "limit",         # Limit order
    #     0.0001,          # Very small amount
    #     1000000          # Very low price (unlikely to execute)
    #   )
    #   
    #   puts "Order placed successfully:"
    #   puts "  Order ID: #{order.id}"
    #   puts "  Type: #{order.type}"
    #   puts "  Amount: #{order.amount}"
    #   puts "  Limit price: #{order.limit}"
    #   puts "  State: #{order.state}"
    #   puts
    #   
    #   # Wait a moment then cancel the order
    #   puts "Cancelling the test order..."
    #   cancelled_order = client.cancel_order(order.id)
    #   puts "Order cancelled. New state: #{cancelled_order.state}"
    #   
    # rescue BudaApi::ApiError => e
    #   puts "Could not place/cancel order: #{e.message}"
    # end
    puts

    # 7. Get recent deposits and withdrawals
    puts "7. Getting recent deposits and withdrawals..."
    
    begin
      withdrawals = client.withdrawals("BTC", page: 1, per_page: 3)
      puts "Recent BTC withdrawals: #{withdrawals[:withdrawals].length}"
      withdrawals[:withdrawals].each do |withdrawal|
        puts "  #{withdrawal.created_at.strftime('%Y-%m-%d')}: #{withdrawal.amount} (#{withdrawal.state})"
      end
      
      deposits = client.deposits("BTC", page: 1, per_page: 3)
      puts "Recent BTC deposits: #{deposits[:deposits].length}"
      deposits[:deposits].each do |deposit|
        puts "  #{deposit.created_at.strftime('%Y-%m-%d')}: #{deposit.amount} (#{deposit.state})"
      end
    rescue BudaApi::ApiError => e
      puts "Could not fetch deposits/withdrawals: #{e.message}"
    end
    puts

    # 8. Demonstrate batch operations
    puts "8. DEMO: Batch operations (cancel multiple orders)"
    puts "This would cancel multiple orders at once and optionally place new ones."
    puts "Skipping for safety in this example."
    
    # Example of batch operations:
    # result = client.batch_orders(
    #   cancel_orders: [order_id_1, order_id_2],
    #   place_orders: [
    #     {
    #       type: "Bid",
    #       price_type: "limit", 
    #       amount: "0.001",
    #       limit: "50000000"
    #     }
    #   ]
    # )

  rescue BudaApi::AuthenticationError => e
    puts "Authentication Error: #{e.message}"
    puts "Please check your API credentials"
  rescue BudaApi::AuthorizationError => e
    puts "Authorization Error: #{e.message}"
    puts "Your API key may not have sufficient permissions"
  rescue BudaApi::RateLimitError => e
    puts "Rate Limit Error: #{e.message}"
    puts "Please wait before making more requests"
  rescue BudaApi::ApiError => e
    puts "API Error: #{e.message}"
    puts "Status code: #{e.status_code}" if e.status_code
    puts "Response: #{e.response_body}" if e.response_body
  rescue BudaApi::ValidationError => e
    puts "Validation Error: #{e.message}"
  rescue => e
    puts "Unexpected Error: #{e.class.name} - #{e.message}"
  end

  puts
  puts "=== Authenticated API example completed ==="
  puts
  puts "IMPORTANT NOTES:"
  puts "- This example uses very small amounts and low prices for safety"
  puts "- Always test on staging environment first if available"
  puts "- Be careful when placing real orders on production"
  puts "- Monitor your orders and cancel them if needed"
end

main if __FILE__ == $0