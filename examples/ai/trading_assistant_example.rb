#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: AI-Enhanced Trading Assistant
# This example demonstrates how to use BudaApi with AI features for comprehensive trading analysis

require 'bundler/setup'
require_relative '../lib/buda_api'

# Configuration
API_KEY = ENV['BUDA_API_KEY'] || 'your_api_key_here'
API_SECRET = ENV['BUDA_API_SECRET'] || 'your_api_secret_here'
LLM_PROVIDER = :openai  # or :anthropic, :ollama

def main
  puts "🤖 BudaApi AI Trading Assistant Example"
  puts "=" * 50
  
  # Check if AI features are available
  unless BudaApi.ai_available?
    puts "❌ AI features are not available. Please install ruby_llm gem:"
    puts "   gem install ruby_llm"
    return
  end
  
  puts "✅ AI features available"
  
  # Initialize authenticated client
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true  # Use sandbox for testing
  )
  
  # Initialize AI trading assistant
  assistant = BudaApi.trading_assistant(client, llm_provider: LLM_PROVIDER)
  
  # Example 1: Market Analysis with AI
  puts "\n📊 Market Analysis"
  puts "-" * 30
  
  market_analysis = assistant.analyze_market("BTC-CLP")
  puts "Market: #{market_analysis[:market_id]}"
  puts "Current Price: #{market_analysis[:current_price]} CLP"
  puts "Trend: #{market_analysis[:trend]}"
  puts "AI Recommendation: #{market_analysis[:ai_recommendation][:action]}"
  puts "Confidence: #{market_analysis[:ai_recommendation][:confidence]}%"
  
  # Example 2: Trading Strategy Suggestions
  puts "\n🎯 Trading Strategy"
  puts "-" * 30
  
  strategy = assistant.suggest_trading_strategy(
    market_id: "BTC-CLP",
    risk_tolerance: "medium",
    investment_horizon: "short_term"
  )
  
  puts "Strategy: #{strategy[:strategy_name]}"
  puts "Entry Range: #{strategy[:entry_signals][:price_range][:min]} - #{strategy[:entry_signals][:price_range][:max]} CLP"
  puts "Target: #{strategy[:profit_targets].first[:price]} CLP (#{strategy[:profit_targets].first[:percentage]}%)"
  puts "Stop Loss: #{strategy[:risk_management][:stop_loss][:price]} CLP"
  
  # Example 3: Entry/Exit Signals
  puts "\n🚦 Entry/Exit Signals"
  puts "-" * 30
  
  signals = assistant.get_entry_exit_signals(["BTC-CLP", "ETH-CLP"])
  
  signals[:signals].each do |signal|
    puts "#{signal[:market_id]}:"
    puts "  Signal: #{signal[:signal]} (#{signal[:strength]})"
    puts "  Price: #{signal[:current_price]} CLP"
    puts "  Recommendation: #{signal[:recommendation]}"
    puts
  end
  
  # Example 4: Natural Language Trading
  puts "\n💬 Natural Language Trading"
  puts "-" * 30
  
  nl_trader = BudaApi.natural_language_trader(client, llm_provider: LLM_PROVIDER)
  
  # Execute natural language commands
  commands = [
    "Check my BTC balance",
    "What's the current price of Ethereum?",
    "Show me the order book for BTC-CLP"
  ]
  
  commands.each do |command|
    puts "Query: #{command}"
    result = nl_trader.execute_command(command, confirm_trades: false)
    puts "Response: #{result[:content] || result[:message]}"
    puts
  end
  
  # Example 5: Risk Management
  puts "\n⚠️ Risk Management"
  puts "-" * 30
  
  risk_manager = BudaApi::AI::RiskManager.new(client, llm_provider: LLM_PROVIDER)
  
  portfolio_risk = risk_manager.analyze_portfolio_risk(include_ai_insights: true)
  
  if portfolio_risk[:type] == :portfolio_risk_analysis
    puts "Portfolio Value: #{portfolio_risk[:portfolio_value].round(2)} CLP"
    puts "Risk Level: #{portfolio_risk[:overall_risk][:color]} #{portfolio_risk[:overall_risk][:level]}"
    puts "Risk Score: #{portfolio_risk[:overall_risk][:score].round(1)}/5.0"
    
    if portfolio_risk[:ai_insights]
      puts "\nAI Risk Insights:"
      puts portfolio_risk[:ai_insights][:analysis]
    end
  else
    puts "Portfolio analysis: #{portfolio_risk[:message]}"
  end
  
  # Example 6: Anomaly Detection
  puts "\n🔍 Anomaly Detection"
  puts "-" * 30
  
  detector = BudaApi::AI::AnomalyDetector.new(client, llm_provider: LLM_PROVIDER)
  
  anomalies = detector.detect_market_anomalies(
    markets: ["BTC-CLP", "ETH-CLP"],
    include_ai_analysis: true
  )
  
  puts "Markets Analyzed: #{anomalies[:markets_analyzed]}"
  puts "Anomalies Detected: #{anomalies[:anomalies_detected]}"
  
  if anomalies[:anomalies_detected] > 0
    puts "\nTop Anomalies:"
    anomalies[:anomalies].first(3).each do |anomaly|
      puts "  #{anomaly[:type]}: #{anomaly[:description]} (#{anomaly[:severity]})"
    end
    
    if anomalies[:ai_analysis]
      puts "\nAI Analysis:"
      puts anomalies[:ai_analysis][:analysis]
    end
  else
    puts "✅ No significant anomalies detected"
  end
  
  # Example 7: Report Generation
  puts "\n📋 Report Generation"
  puts "-" * 30
  
  reporter = BudaApi::AI::ReportGenerator.new(client, llm_provider: LLM_PROVIDER)
  
  portfolio_report = reporter.generate_portfolio_summary(
    format: "markdown",
    include_ai: true
  )
  
  if portfolio_report[:type] == :portfolio_summary_report
    puts "Report generated successfully!"
    puts "Format: #{portfolio_report[:format]}"
    
    # Save report to file
    filename = "portfolio_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.md"
    File.write(filename, portfolio_report[:formatted_content])
    puts "Report saved to: #{filename}"
  else
    puts "Report generation: #{portfolio_report[:message] || portfolio_report[:error]}"
  end
  
  # Example 8: Custom AI Analysis
  puts "\n🧠 Custom AI Analysis"
  puts "-" * 30
  
  custom_prompt = "Analyze the Chilean cryptocurrency market trends and provide investment recommendations for the next week"
  
  custom_report = reporter.generate_custom_report(
    custom_prompt,
    [:portfolio, :market],
    format: "text"
  )
  
  if custom_report[:ai_analysis]
    puts "Custom Analysis:"
    puts custom_report[:ai_analysis][:content]
  else
    puts "Custom analysis not available"
  end
  
rescue BudaApi::AuthenticationError
  puts "❌ Authentication failed. Please check your API credentials."
rescue BudaApi::ApiError => e
  puts "❌ API Error: #{e.message}"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
end

# Interactive mode
def interactive_mode
  puts "\n🎮 Interactive AI Trading Mode"
  puts "Type 'help' for commands, 'exit' to quit"
  puts "-" * 40
  
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true
  )
  
  nl_trader = BudaApi.natural_language_trader(client, llm_provider: LLM_PROVIDER)
  
  loop do
    print "\n💬 Ask me anything about trading: "
    input = gets.chomp
    
    case input.downcase
    when 'exit', 'quit'
      puts "👋 Goodbye!"
      break
    when 'help'
      show_help
    when 'clear'
      nl_trader.clear_history
      puts "🧹 Conversation history cleared"
    else
      if input.strip.empty?
        puts "Please enter a command or question"
        next
      end
      
      puts "🤔 Processing..."
      result = nl_trader.execute_command(input, confirm_trades: true)
      
      case result[:type]
      when :text_response
        puts "🤖 #{result[:content]}"
      when :confirmation_required
        puts "⚠️ #{result[:message]}"
        print "Confirm? (y/n): "
        confirm = gets.chomp.downcase
        if confirm == 'y' || confirm == 'yes'
          # Would execute the confirmed action
          puts "✅ Action confirmed (demo mode - not actually executed)"
        else
          puts "❌ Action cancelled"
        end
      when :order_placed
        puts "✅ #{result[:message]}"
      when :balance_info
        puts "💰 #{result[:message]}"
      when :market_data
        puts "📊 #{result[:message]}"
      when :error
        puts "❌ #{result[:error]}"
      else
        puts "📋 #{result[:message] || 'Action completed'}"
      end
    end
  end
end

def show_help
  puts """
Available commands:
  - Check my [currency] balance
  - What's the price of [crypto]?
  - Buy/sell [amount] [crypto]
  - Show order book for [market]
  - Get market analysis for [market]
  - What are the best trading opportunities?
  - Analyze my portfolio risk
  - Generate a trading report
  
Special commands:
  - help: Show this help
  - clear: Clear conversation history  
  - exit: Quit interactive mode
"""
end

if __FILE__ == $0
  puts "Choose mode:"
  puts "1. Run examples (default)"
  puts "2. Interactive mode"
  print "Selection (1-2): "
  
  choice = gets.chomp
  
  case choice
  when '2'
    interactive_mode if BudaApi.ai_available?
  else
    main
  end
end