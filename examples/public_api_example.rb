#!/usr/bin/env ruby
# frozen_string_literal: true

# Basic public API usage example
#
# This example shows how to use the public API endpoints that don't require authentication

require_relative "../lib/buda_api"

def main
  puts "=== Buda API Ruby SDK - Public API Example ==="
  puts

  # Configure the SDK
  BudaApi.configure do |config|
    config.debug_mode = true  # Enable debug logging
    config.timeout = 60      # Increase timeout to 60 seconds
  end

  # Create a public client
  client = BudaApi.public_client

  begin
    # 1. Get all available markets
    puts "1. Fetching all available markets..."
    markets = client.markets
    puts "Found #{markets.length} markets:"
    
    markets.first(5).each do |market|
      puts "  - #{market.id}: #{market.name} (#{market.base_currency}/#{market.quote_currency})"
      puts "    Minimum order: #{market.minimum_order_amount}"
    end
    puts "  ... and #{markets.length - 5} more" if markets.length > 5
    puts

    # 2. Get specific market details
    market_id = "BTC-CLP"
    puts "2. Getting details for #{market_id}..."
    market = client.market_details(market_id)
    puts "Market: #{market.name}"
    puts "Base currency: #{market.base_currency}"
    puts "Quote currency: #{market.quote_currency}"
    puts "Minimum order amount: #{market.minimum_order_amount}"
    puts

    # 3. Get ticker information
    puts "3. Getting ticker for #{market_id}..."
    ticker = client.ticker(market_id)
    puts "Last price: #{ticker.last_price}"
    puts "Min ask: #{ticker.min_ask}"
    puts "Max bid: #{ticker.max_bid}"
    puts "Volume (24h): #{ticker.volume}"
    puts "Price change (24h): #{ticker.price_variation_24h}%"
    puts "Price change (7d): #{ticker.price_variation_7d}%"
    puts

    # 4. Get order book
    puts "4. Getting order book for #{market_id}..."
    order_book = client.order_book(market_id)
    
    puts "Best ask: #{order_book.best_ask.price} (#{order_book.best_ask.amount})"
    puts "Best bid: #{order_book.best_bid.price} (#{order_book.best_bid.amount})"
    puts "Spread: #{order_book.spread} (#{order_book.spread_percentage}%)"
    
    puts "\nTop 3 asks:"
    order_book.asks.first(3).each_with_index do |ask, i|
      puts "  #{i + 1}. #{ask.price} x #{ask.amount} = #{ask.total}"
    end
    
    puts "\nTop 3 bids:"
    order_book.bids.first(3).each_with_index do |bid, i|
      puts "  #{i + 1}. #{bid.price} x #{bid.amount} = #{bid.total}"
    end
    puts

    # 5. Get recent trades
    puts "5. Getting recent trades for #{market_id}..."
    trades = client.trades(market_id, limit: 5)
    
    puts "Recent trades (#{trades.count} total):"
    trades.each do |trade|
      puts "  #{trade.timestamp.strftime('%H:%M:%S')}: #{trade.amount} at #{trade.price} (#{trade.direction})"
    end
    puts

    # 6. Get quotation
    puts "6. Getting quotation for buying 0.001 BTC..."
    quotation = client.quotation(market_id, "bid_given_size", 0.001)
    puts "Quotation type: #{quotation.type}"
    puts "Amount: #{quotation.amount}"
    puts "You would pay: #{quotation.quote_balance_change}"
    puts "Fee: #{quotation.fee}"
    puts

    # 7. Get market reports
    puts "7. Getting average price report for the last 24 hours..."
    start_time = Time.now - 86400  # 24 hours ago
    avg_prices = client.average_prices_report(market_id, start_at: start_time)
    
    if avg_prices.any?
      puts "Average price data points: #{avg_prices.length}"
      puts "First data point: #{avg_prices.first.average} at #{avg_prices.first.timestamp}"
      puts "Last data point: #{avg_prices.last.average} at #{avg_prices.last.timestamp}"
    else
      puts "No average price data available for the specified period"
    end
    puts

    puts "8. Getting candlestick report for the last 24 hours..."
    candles = client.candlestick_report(market_id, start_at: start_time)
    
    if candles.any?
      puts "Candlestick data points: #{candles.length}"
      last_candle = candles.last
      puts "Last candle:"
      puts "  Time: #{last_candle.timestamp}"
      puts "  Open: #{last_candle.open}"
      puts "  High: #{last_candle.high}"
      puts "  Low: #{last_candle.low}"
      puts "  Close: #{last_candle.close}"
      puts "  Volume: #{last_candle.volume}"
    else
      puts "No candlestick data available for the specified period"
    end

  rescue BudaApi::ApiError => e
    puts "API Error: #{e.message}"
    puts "Status code: #{e.status_code}" if e.status_code
    puts "Response: #{e.response_body}" if e.response_body
  rescue BudaApi::ConnectionError => e
    puts "Connection Error: #{e.message}"
  rescue BudaApi::ValidationError => e
    puts "Validation Error: #{e.message}"
  rescue => e
    puts "Unexpected Error: #{e.class.name} - #{e.message}"
  end

  puts
  puts "=== Example completed ==="
end

main if __FILE__ == $0