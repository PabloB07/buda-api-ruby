#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Natural Language Trading Interface
# This example demonstrates conversational trading using natural language processing

require 'bundler/setup'
require_relative '../../lib/buda_api'

# Configuration
API_KEY = ENV['BUDA_API_KEY'] || 'your_api_key_here'
API_SECRET = ENV['BUDA_API_SECRET'] || 'your_api_secret_here'

class TradingChatBot
  def initialize(client, llm_provider = :openai)
    @client = client
    @nl_trader = BudaApi.natural_language_trader(client, llm_provider: llm_provider)
    @conversation_active = true
    @demo_mode = true  # Safety flag
    
    puts "🤖 AI Trading Assistant initialized!"
    puts "Demo mode: #{@demo_mode ? 'ON (safe)' : 'OFF (live trading)'}"
  end
  
  def start_conversation
    puts "\n💬 Natural Language Trading Interface"
    puts "=" * 50
    puts "You can ask me about:"
    puts "• Account balances and portfolio status"
    puts "• Current market prices and trends" 
    puts "• Trading opportunities and analysis"
    puts "• Risk assessment and recommendations"
    puts "• Market data and order books"
    puts "• Place orders (with confirmation)"
    puts
    puts "Type 'help' for more commands, 'exit' to quit"
    puts "-" * 50
    
    while @conversation_active
      print "\n💭 You: "
      user_input = gets.chomp.strip
      
      next if user_input.empty?
      
      handle_user_input(user_input)
    end
  end
  
  private
  
  def handle_user_input(input)
    case input.downcase
    when 'exit', 'quit', 'bye'
      puts "🤖 Goodbye! Happy trading! 👋"
      @conversation_active = false
    when 'help'
      show_help_menu
    when 'clear', 'reset'
      @nl_trader.clear_history
      puts "🤖 Conversation history cleared!"
    when 'demo on', 'safety on'
      @demo_mode = true
      puts "🤖 Demo mode enabled - no real trades will be executed"
    when 'demo off', 'safety off'
      puts "⚠️ Are you sure you want to enable live trading? (yes/no)"
      confirmation = gets.chomp.downcase
      if confirmation == 'yes'
        @demo_mode = false
        puts "🤖 ⚠️ LIVE TRADING MODE ENABLED - Real trades will be executed!"
      else
        puts "🤖 Demo mode remains enabled"
      end
    when /^examples?$/
      show_example_queries
    else
      process_trading_query(input)
    end
  end
  
  def process_trading_query(input)
    puts "🤖 Processing your request..."
    
    begin
      # Execute the natural language command
      result = @nl_trader.execute_command(input, confirm_trades: !@demo_mode)
      
      # Handle different response types
      case result[:type]
      when :text_response
        puts "🤖 #{result[:content]}"
        
      when :balance_info
        display_balance_info(result)
        
      when :market_data
        display_market_data(result)
        
      when :quotation
        display_quotation_info(result)
        
      when :order_history
        display_order_history(result)
        
      when :confirmation_required
        handle_trade_confirmation(result)
        
      when :order_placed
        display_order_success(result)
        
      when :order_cancelled
        puts "🤖 ✅ #{result[:message]}"
        
      when :error
        puts "🤖 ❌ #{result[:error]}"
        suggest_alternatives(input)
        
      else
        puts "🤖 #{result[:message] || 'Request processed'}"
      end
      
    rescue BudaApi::ApiError => e
      puts "🤖 ❌ API Error: #{e.message}"
      suggest_api_solutions(e)
    rescue => e
      puts "🤖 ❌ Unexpected error: #{e.message}"
      puts "Please try rephrasing your request or type 'help' for guidance."
    end
  end
  
  def display_balance_info(result)
    puts "🤖 💰 Balance Information:"
    puts "   Currency: #{result[:currency]}"
    puts "   Available: #{result[:available]} #{result[:currency]}"
    puts "   Total: #{result[:total]} #{result[:currency]}"
    
    if result[:frozen] > 0
      puts "   Frozen: #{result[:frozen]} #{result[:currency]}"
    end
    
    if result[:pending_withdrawals] > 0
      puts "   Pending Withdrawals: #{result[:pending_withdrawals]} #{result[:currency]}"
    end
  end
  
  def display_market_data(result)
    change_emoji = result[:change_24h] >= 0 ? "📈" : "📉"
    change_color = result[:change_24h] >= 0 ? "+" : ""
    
    puts "🤖 📊 Market Data for #{result[:market_id]}:"
    puts "   Current Price: #{result[:price]} CLP"
    puts "   24h Change: #{change_emoji} #{change_color}#{result[:change_24h].round(2)}%"
    puts "   24h Volume: #{result[:volume].round(2)}"
    puts "   Best Bid: #{result[:best_bid]} CLP"
    puts "   Best Ask: #{result[:best_ask]} CLP"
    puts "   Spread: #{result[:spread].round(4)}%"
  end
  
  def display_quotation_info(result)
    puts "🤖 💱 Price Quotation:"
    puts "   To #{result[:side]} #{result[:amount]} #{result[:market_id].split('-').first}:"
    puts "   Estimated Cost: #{result[:estimated_cost]} CLP"
    puts "   Trading Fee: #{result[:fee]} CLP"
    puts "   Total: #{(result[:estimated_cost].abs + result[:fee]).round(2)} CLP"
  end
  
  def display_order_history(result)
    puts "🤖 📋 Recent Orders for #{result[:market_id]}:"
    
    if result[:orders].empty?
      puts "   No recent orders found"
      return
    end
    
    puts "   Found #{result[:orders_count]} orders:"
    puts
    
    result[:orders].first(5).each do |order|
      status_emoji = case order[:state]
        when "traded" then "✅"
        when "pending" then "⏳"
        when "cancelled" then "❌"
        else "❓"
      end
      
      price_info = order[:price] ? "@ #{order[:price]} CLP" : "(market price)"
      
      puts "   #{status_emoji} #{order[:type].upcase} #{order[:amount]} #{price_info}"
      puts "     ID: #{order[:id]} | Status: #{order[:state]} | #{order[:created_at]}"
    end
  end
  
  def handle_trade_confirmation(result)
    return execute_demo_trade(result) if @demo_mode
    
    puts "🤖 ⚠️ Trade Confirmation Required:"
    puts "   #{result[:message]}"
    puts
    print "   Do you want to proceed? (yes/no): "
    
    confirmation = gets.chomp.downcase
    
    if %w[yes y confirm].include?(confirmation)
      puts "🤖 Executing trade..."
      # In a real implementation, this would execute the confirmed trade
      puts "✅ Trade executed successfully! (This is a demo)"
    else
      puts "🤖 Trade cancelled as requested"
    end
  end
  
  def execute_demo_trade(result)
    puts "🤖 🎭 Demo Trade Simulation:"
    puts "   #{result[:message]}"
    puts "   ✅ Would be executed in live mode"
    puts "   💡 Enable live trading with 'demo off' command"
  end
  
  def display_order_success(result)
    puts "🤖 ✅ Order Placed Successfully!"
    puts "   Order ID: #{result[:order_id]}"
    puts "   Market: #{result[:market_id]}"
    puts "   Side: #{result[:side].upcase}"
    puts "   Amount: #{result[:amount]}"
    puts "   Price: #{result[:price] || 'Market Price'}"
    puts "   Status: #{result[:status]}"
  end
  
  def suggest_alternatives(original_input)
    suggestions = [
      "Try: 'Check my BTC balance'",
      "Try: 'What's the current price of Bitcoin?'", 
      "Try: 'Show me the ETH order book'",
      "Try: 'Get a quote for buying 0.001 BTC'",
      "Type 'examples' to see more query examples"
    ]
    
    puts "🤖 💡 Here are some things you can try:"
    suggestions.each { |suggestion| puts "   #{suggestion}" }
  end
  
  def suggest_api_solutions(error)
    case error.message
    when /authentication/i
      puts "🤖 💡 This might be an authentication issue:"
      puts "   • Check your API credentials"
      puts "   • Make sure your API key has the required permissions"
    when /not found/i
      puts "🤖 💡 This resource might not exist:"
      puts "   • Check market names (e.g., 'BTC-CLP', 'ETH-CLP')"
      puts "   • Verify currency codes are supported"
    when /rate limit/i
      puts "🤖 💡 API rate limit exceeded:"
      puts "   • Please wait a moment and try again"
      puts "   • Consider spacing out your requests"
    else
      puts "🤖 💡 You can try:"
      puts "   • Check your internet connection"
      puts "   • Try a different query"
      puts "   • Contact support if the issue persists"
    end
  end
  
  def show_help_menu
    puts """
🤖 Trading Assistant Help Menu
════════════════════════════════

💰 BALANCE QUERIES:
   • "Check my BTC balance"
   • "Show all my balances"
   • "How much Ethereum do I have?"

📊 MARKET DATA:
   • "What's the Bitcoin price?"
   • "Show BTC-CLP market data"
   • "Get ETH order book"
   • "What are the current spreads?"

💱 PRICE QUOTES:
   • "Quote for buying 0.001 BTC"
   • "How much to sell 1 ETH?"
   • "Price for 100000 CLP of Bitcoin"

📋 ORDER MANAGEMENT:
   • "Show my recent orders"
   • "Cancel order 12345"
   • "Order history for BTC-CLP"

🎯 TRADING (Demo Mode):
   • "Buy 0.001 BTC at market price"
   • "Sell 0.5 ETH at 2000000 CLP"
   • "Place limit order for Bitcoin"

🧠 ANALYSIS:
   • "Analyze Bitcoin market"
   • "What are good trading opportunities?"
   • "Risk assessment for my portfolio"

⚙️ COMMANDS:
   • help - Show this help
   • examples - Show example queries
   • clear - Clear conversation history
   • demo on/off - Toggle trading mode
   • exit - Quit assistant

🛡️ SAFETY FEATURES:
   • Demo mode prevents real trades
   • All orders require confirmation
   • Clear error messages and suggestions
"""
  end
  
  def show_example_queries
    puts """
🤖 Example Queries You Can Try
══════════════════════════════

💰 "Check my Bitcoin balance"
📊 "What's the current price of Ethereum in CLP?"
📈 "Show me the BTC-CLP order book"
💱 "How much would it cost to buy 0.001 BTC?"
📋 "Show my last 10 orders"
🎯 "I want to buy 50000 CLP worth of Bitcoin"
🔍 "What's the spread on ETH-CLP?"
📊 "Give me market data for all major coins"
🧠 "Analyze the Bitcoin market trends"
⚠️ "What are the risks in my current portfolio?"
💡 "What are the best trading opportunities right now?"
🎲 "Should I buy or sell Bitcoin today?"

Try any of these or ask in your own words!
"""
  end
end

def main
  puts "🚀 Natural Language Trading Interface"
  puts "=" * 50
  
  unless BudaApi.ai_available?
    puts "❌ AI features not available. Please install ruby_llm gem:"
    puts "   gem install ruby_llm"
    return
  end
  
  # Initialize client
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true  # Use sandbox for safety
  )
  
  # Create and start chat bot
  bot = TradingChatBot.new(client, :openai)
  bot.start_conversation
  
rescue BudaApi::AuthenticationError
  puts "❌ Authentication failed. Please check your API credentials."
  puts "Set environment variables:"
  puts "   export BUDA_API_KEY='your_key'"
  puts "   export BUDA_API_SECRET='your_secret'"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
end

if __FILE__ == $0
  main
end