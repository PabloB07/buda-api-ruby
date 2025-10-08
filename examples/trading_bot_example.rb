#!/usr/bin/env ruby
# frozen_string_literal: true

# Advanced trading bot example
#
# This example demonstrates a simple trading bot that monitors price changes
# and can place orders based on basic strategies

require_relative "../lib/buda_api"
require "dotenv/load"

class SimpleTradingBot
  def initialize(api_key, api_secret, market_id = "BTC-CLP")
    @client = BudaApi.authenticated_client(
      api_key: api_key,
      api_secret: api_secret
    )
    @public_client = BudaApi.public_client
    @market_id = market_id
    @running = false
    @price_history = []
    @max_history = 20
  end

  def start
    puts "=== Simple Trading Bot Started ==="
    puts "Market: #{@market_id}"
    puts "Press Ctrl+C to stop"
    puts

    @running = true
    
    # Set up signal handler for graceful shutdown
    trap("INT") do
      puts "\nReceived interrupt signal. Stopping bot..."
      @running = false
    end

    monitor_loop
  end

  private

  def monitor_loop
    while @running
      begin
        # Get current market data
        ticker = @public_client.ticker(@market_id)
        current_price = ticker.last_price.amount
        
        # Update price history
        @price_history << {
          price: current_price,
          timestamp: Time.now
        }
        
        # Keep only recent history
        @price_history = @price_history.last(@max_history)
        
        # Display current status
        display_status(ticker)
        
        # Check for trading opportunities
        check_trading_opportunities(current_price)
        
        # Wait before next check
        sleep 30  # Check every 30 seconds
        
      rescue BudaApi::RateLimitError => e
        puts "Rate limit hit. Waiting 60 seconds..."
        sleep 60
      rescue BudaApi::ApiError => e
        puts "API Error: #{e.message}"
        sleep 10
      rescue => e
        puts "Unexpected error: #{e.message}"
        sleep 10
      end
    end
    
    puts "Bot stopped."
  end

  def display_status(ticker)
    puts "\n=== Market Status at #{Time.now.strftime('%H:%M:%S')} ==="
    puts "Last price: #{ticker.last_price}"
    puts "24h change: #{ticker.price_variation_24h}%"
    puts "Volume: #{ticker.volume}"
    puts "Spread: #{ticker.min_ask.amount - ticker.max_bid.amount}"
    
    if @price_history.length > 1
      price_change = @price_history.last[:price] - @price_history.first[:price]
      change_pct = (price_change / @price_history.first[:price] * 100).round(2)
      puts "Recent trend: #{change_pct}% over #{@price_history.length} checks"
    end
    
    display_balances
  end

  def display_balances
    begin
      base_currency = @market_id.split("-").first
      quote_currency = @market_id.split("-").last
      
      base_balance = @client.balance(base_currency)
      quote_balance = @client.balance(quote_currency)
      
      puts "\nBalances:"
      puts "#{base_currency}: #{base_balance.available_amount} available"
      puts "#{quote_currency}: #{quote_balance.available_amount} available"
    rescue BudaApi::ApiError => e
      puts "Could not fetch balances: #{e.message}"
    end
  end

  def check_trading_opportunities(current_price)
    return if @price_history.length < 5
    
    # Simple moving average strategy
    recent_prices = @price_history.last(5).map { |h| h[:price] }
    sma = recent_prices.sum / recent_prices.length
    
    puts "\nStrategy Analysis:"
    puts "Current price: #{current_price}"
    puts "5-period SMA: #{sma.round(2)}"
    
    price_above_sma = current_price > sma * 1.02  # 2% above SMA
    price_below_sma = current_price < sma * 0.98  # 2% below SMA
    
    if price_above_sma
      puts "🔴 Price significantly above SMA - Consider selling"
      # suggest_sell_order(current_price)
    elsif price_below_sma
      puts "🟢 Price significantly below SMA - Consider buying" 
      # suggest_buy_order(current_price)
    else
      puts "📊 Price near SMA - No clear signal"
    end
    
    # Check for rapid price changes
    if @price_history.length >= 3
      recent_change = (current_price - @price_history[-3][:price]) / @price_history[-3][:price]
      if recent_change.abs > 0.05  # 5% change in 3 periods
        direction = recent_change > 0 ? "📈 UP" : "📉 DOWN"
        puts "⚠️  Rapid price movement detected: #{direction} #{(recent_change * 100).round(2)}%"
      end
    end
  end

  def suggest_buy_order(current_price)
    puts "\n💡 Buy Order Suggestion:"
    
    # Calculate suggested buy price (slightly below current price)
    suggested_price = current_price * 0.995
    suggested_amount = 0.001  # Small test amount
    
    begin
      quotation = @client.quotation(@market_id, "bid_given_size", suggested_amount)
      
      puts "Suggested buy order:"
      puts "  Amount: #{suggested_amount} BTC"
      puts "  Price: #{suggested_price}"
      puts "  Estimated cost: #{quotation.quote_balance_change}"
      puts "  Fee: #{quotation.fee}"
      puts
      puts "⚠️  This is just a suggestion. Review carefully before placing any orders!"
      
      # Uncomment to actually place orders (BE VERY CAREFUL!)
      # place_buy_order(suggested_amount, suggested_price)
      
    rescue BudaApi::ApiError => e
      puts "Could not get quotation: #{e.message}"
    end
  end

  def suggest_sell_order(current_price)
    puts "\n💡 Sell Order Suggestion:"
    
    # Calculate suggested sell price (slightly above current price)
    suggested_price = current_price * 1.005
    suggested_amount = 0.001  # Small test amount
    
    begin
      quotation = @client.quotation(@market_id, "ask_given_size", suggested_amount)
      
      puts "Suggested sell order:"
      puts "  Amount: #{suggested_amount} BTC"
      puts "  Price: #{suggested_price}"
      puts "  Estimated proceeds: #{quotation.quote_balance_change}"
      puts "  Fee: #{quotation.fee}"
      puts
      puts "⚠️  This is just a suggestion. Review carefully before placing any orders!"
      
      # Uncomment to actually place orders (BE VERY CAREFUL!)
      # place_sell_order(suggested_amount, suggested_price)
      
    rescue BudaApi::ApiError => e
      puts "Could not get quotation: #{e.message}"
    end
  end

  # DANGEROUS: Only uncomment if you want to place actual orders
  def place_buy_order(amount, price)
    puts "🚨 PLACING ACTUAL BUY ORDER 🚨"
    
    order = @client.place_order(@market_id, "Bid", "limit", amount, price)
    puts "✅ Buy order placed: ##{order.id}"
    
    # Store order ID for potential cancellation
    @active_orders ||= []
    @active_orders << order.id
  end

  def place_sell_order(amount, price)  
    puts "🚨 PLACING ACTUAL SELL ORDER 🚨"
    
    order = @client.place_order(@market_id, "Ask", "limit", amount, price)
    puts "✅ Sell order placed: ##{order.id}"
    
    # Store order ID for potential cancellation
    @active_orders ||= []
    @active_orders << order.id
  end

  def cancel_all_orders
    return unless @active_orders&.any?
    
    puts "Cancelling all active orders..."
    
    @active_orders.each do |order_id|
      begin
        @client.cancel_order(order_id)
        puts "Cancelled order ##{order_id}"
      rescue BudaApi::ApiError => e
        puts "Could not cancel order ##{order_id}: #{e.message}"
      end
    end
    
    @active_orders.clear
  end
end

def main
  puts "=== Buda API Ruby SDK - Trading Bot Example ==="
  puts

  # Load credentials
  api_key = ENV["BUDA_API_KEY"]
  api_secret = ENV["BUDA_API_SECRET"]

  if api_key.nil? || api_secret.nil?
    puts "ERROR: Please set BUDA_API_KEY and BUDA_API_SECRET environment variables"
    return
  end

  # Configure for safe testing
  BudaApi.configure do |config|
    config.debug_mode = false  # Disable debug to reduce noise
    config.timeout = 30
  end

  market_id = ARGV[0] || "BTC-CLP"
  
  puts "IMPORTANT DISCLAIMER:"
  puts "==================="
  puts "This is a DEMO trading bot for educational purposes only."
  puts "It does NOT place actual orders by default."
  puts "Trading cryptocurrencies involves substantial risk of loss."
  puts "Never risk more than you can afford to lose."
  puts "Always test thoroughly in a staging environment first."
  puts
  puts "Press Enter to continue or Ctrl+C to exit..."
  gets

  bot = SimpleTradingBot.new(api_key, api_secret, market_id)
  bot.start
end

main if __FILE__ == $0