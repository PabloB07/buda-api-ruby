#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Advanced Risk Management with AI
# This example demonstrates comprehensive risk management using AI-powered analysis

require 'bundler/setup'
require_relative '../../lib/buda_api'

# Configuration
API_KEY = ENV['BUDA_API_KEY'] || 'your_api_key_here'
API_SECRET = ENV['BUDA_API_SECRET'] || 'your_api_secret_here'

def main
  puts "⚠️ Advanced AI Risk Management Example"
  puts "=" * 50
  
  unless BudaApi.ai_available?
    puts "❌ AI features not available. Install ruby_llm gem first."
    return
  end
  
  # Initialize client and risk manager
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true
  )
  
  risk_manager = BudaApi::AI::RiskManager.new(client, llm_provider: :openai)
  
  # Example 1: Comprehensive Portfolio Risk Analysis
  puts "\n📊 Portfolio Risk Analysis"
  puts "-" * 30
  
  portfolio_risk = risk_manager.analyze_portfolio_risk(
    include_ai_insights: true,
    focus_factors: ["concentration_risk", "volatility_risk"]
  )
  
  if portfolio_risk[:type] == :portfolio_risk_analysis
    puts "Portfolio Overview:"
    puts "  Total Value: #{portfolio_risk[:portfolio_value].round(2)} CLP"
    puts "  Risk Level: #{portfolio_risk[:overall_risk][:color]} #{portfolio_risk[:overall_risk][:level]}"
    puts "  Risk Score: #{portfolio_risk[:overall_risk][:score].round(1)}/5.0"
    puts "  Holdings: #{portfolio_risk[:currency_count]} different currencies"
    
    puts "\nRisk Breakdown:"
    risk_components = portfolio_risk[:overall_risk][:components]
    puts "  Concentration Risk: #{risk_components[:concentration].round(1)}/5.0"
    puts "  Volatility Risk: #{risk_components[:volatility].round(1)}/5.0"
    puts "  Diversification Risk: #{risk_components[:diversification].round(1)}/5.0"
    puts "  Correlation Risk: #{risk_components[:correlation].round(1)}/5.0"
    
    puts "\nTop Holdings:"
    portfolio_risk[:holdings].first(3).each do |holding|
      percentage = (holding[:amount] / portfolio_risk[:portfolio_value]) * 100
      puts "  #{holding[:currency]}: #{holding[:amount].round(4)} (#{percentage.round(1)}%)"
    end
    
    if portfolio_risk[:recommendations].any?
      puts "\nRecommendations:"
      portfolio_risk[:recommendations].each do |rec|
        puts "  #{rec[:type].upcase}: #{rec[:message]}"
      end
    end
    
    if portfolio_risk[:ai_insights]
      puts "\nAI Risk Insights:"
      puts portfolio_risk[:ai_insights][:analysis]
    end
  else
    puts "Portfolio Risk: #{portfolio_risk[:message]}"
  end
  
  # Example 2: Pre-Trade Risk Evaluation
  puts "\n🎯 Pre-Trade Risk Evaluation"
  puts "-" * 30
  
  # Evaluate risk for a potential BTC purchase
  trade_risk = risk_manager.evaluate_trade_risk(
    "BTC-CLP",
    "buy",
    0.001,  # 0.001 BTC
    nil     # Market price
  )
  
  if trade_risk[:type] == :trade_risk_evaluation
    puts "Trade Risk Assessment:"
    puts "  Market: #{trade_risk[:market_id]}"
    puts "  Side: #{trade_risk[:side]} #{trade_risk[:amount]} BTC"
    puts "  Risk Level: #{RISK_LEVELS[trade_risk[:risk_level]][:color]} #{RISK_LEVELS[trade_risk[:risk_level]][:description]}"
    puts "  Risk Score: #{trade_risk[:risk_score].round(1)}/5.0"
    puts "  Should Proceed: #{trade_risk[:should_proceed] ? '✅ Yes' : '❌ No'}"
    
    puts "\nRisk Factors:"
    puts "  Position Impact: #{trade_risk[:position_risk][:portfolio_percentage].round(1)}% of portfolio"
    puts "  Market Impact: #{trade_risk[:market_impact_risk][:impact_score].round(1)}/5.0"
    puts "  Trade Value: #{trade_risk[:trade_impact][:estimated_cost].round(2)} CLP"
    
    puts "\nRecommendations:"
    trade_risk[:recommendations].each do |recommendation|
      puts "  • #{recommendation}"
    end
  end
  
  # Example 3: Risk Monitoring with Alerts
  puts "\n🚨 Risk Threshold Monitoring"
  puts "-" * 30
  
  # Set custom risk thresholds
  thresholds = {
    max_position_percentage: 25.0,    # Max 25% in single asset
    max_daily_loss: 3.0,             # Max 3% daily loss
    min_diversification_score: 0.7,   # Min diversification
    max_volatility_score: 3.5         # Max volatility tolerance
  }
  
  monitoring_result = risk_manager.monitor_risk_thresholds(thresholds)
  
  puts "Risk Monitoring Results:"
  puts "  Alerts Detected: #{monitoring_result[:alerts_count]}"
  puts "  Portfolio Safe: #{monitoring_result[:safe] ? '✅ Yes' : '❌ No'}"
  
  if monitoring_result[:alerts].any?
    puts "\nActive Alerts:"
    monitoring_result[:alerts].each do |alert|
      level_emoji = case alert[:level]
        when :high then "🚨"
        when :medium then "⚠️"
        else "ℹ️"
      end
      puts "  #{level_emoji} #{alert[:message]}"
    end
  end
  
  puts "\nCurrent Thresholds:"
  monitoring_result[:thresholds].each do |name, value|
    puts "  #{name}: #{value}"
  end
  
  # Example 4: Stop-Loss Recommendations
  puts "\n🛡️ Stop-Loss Recommendations"
  puts "-" * 30
  
  # Assume we have a BTC position to protect
  position_size = 0.005  # 0.005 BTC
  
  stop_loss_rec = risk_manager.recommend_stop_loss("BTC-CLP", position_size)
  
  if stop_loss_rec[:type] == :stop_loss_recommendations
    puts "Stop-Loss Analysis for #{stop_loss_rec[:position_size]} BTC:"
    puts "Current Price: #{stop_loss_rec[:current_price]} CLP"
    puts "Position Value: #{stop_loss_rec[:position_value].round(2)} CLP"
    
    puts "\nStop-Loss Options:"
    stop_loss_rec[:recommendations].each do |name, option|
      puts "  #{name.capitalize}:"
      puts "    Price: #{option[:price].round(2)} CLP"
      puts "    Max Loss: #{option[:max_loss].round(2)} CLP (#{option[:percentage]}%)"
      puts "    Description: #{option[:description]}"
      puts
    end
    
    recommended = stop_loss_rec[:recommendation]
    puts "💡 Recommended: #{recommended} stop-loss based on current market conditions"
  end
  
  # Example 5: Risk-Adjusted Position Sizing
  puts "\n📏 Risk-Adjusted Position Sizing"
  puts "-" * 30
  
  # Calculate optimal position size based on risk tolerance
  def calculate_optimal_position_size(portfolio_value, risk_per_trade_percent, stop_loss_percent)
    risk_amount = portfolio_value * (risk_per_trade_percent / 100.0)
    position_size_clp = risk_amount / (stop_loss_percent / 100.0)
    position_size_clp
  end
  
  portfolio_value = portfolio_risk[:portfolio_value] || 1000000  # 1M CLP default
  risk_per_trade = 2.0  # Risk 2% per trade
  stop_loss_distance = 5.0  # 5% stop loss
  
  optimal_position_clp = calculate_optimal_position_size(
    portfolio_value, 
    risk_per_trade, 
    stop_loss_distance
  )
  
  puts "Position Sizing Calculation:"
  puts "  Portfolio Value: #{portfolio_value.round(2)} CLP"
  puts "  Risk Per Trade: #{risk_per_trade}%"
  puts "  Stop Loss Distance: #{stop_loss_distance}%"
  puts "  Optimal Position Size: #{optimal_position_clp.round(2)} CLP"
  puts "  Max Risk Amount: #{(portfolio_value * risk_per_trade / 100.0).round(2)} CLP"
  
  # Example 6: Correlation Analysis
  puts "\n🔗 Asset Correlation Analysis"
  puts "-" * 30
  
  # Simplified correlation analysis using current price changes
  def analyze_correlations(client, markets)
    correlations = {}
    
    markets.each do |market1|
      markets.each do |market2|
        next if market1 == market2
        
        begin
          ticker1 = client.ticker(market1)
          ticker2 = client.ticker(market2)
          
          # Simple correlation based on 24h changes (in real implementation, use historical data)
          change1 = ticker1.price_variation_24h
          change2 = ticker2.price_variation_24h
          
          # Simplified correlation indicator
          correlation = case
            when (change1 > 0 && change2 > 0) || (change1 < 0 && change2 < 0)
              (change1 * change2).abs / ([change1.abs, change2.abs].max + 0.01)
            else
              -(change1 * change2).abs / ([change1.abs, change2.abs].max + 0.01)
          end
          
          correlations["#{market1}-#{market2}"] = correlation.round(2)
        rescue
          # Skip if unable to get data
        end
      end
    end
    
    correlations
  end
  
  major_markets = ["BTC-CLP", "ETH-CLP"]
  correlations = analyze_correlations(client, major_markets)
  
  puts "Asset Correlation Analysis:"
  correlations.each do |pair, correlation|
    correlation_level = case correlation.abs
      when 0.8..1.0 then "Very High"
      when 0.6..0.8 then "High" 
      when 0.4..0.6 then "Medium"
      when 0.2..0.4 then "Low"
      else "Very Low"
    end
    
    direction = correlation > 0 ? "Positive" : "Negative"
    puts "  #{pair}: #{correlation} (#{direction} #{correlation_level})"
  end
  
  # Example 7: Risk Dashboard Summary
  puts "\n📋 Risk Dashboard Summary"
  puts "=" * 50
  
  dashboard = {
    portfolio_health: portfolio_risk[:overall_risk][:level],
    active_alerts: monitoring_result[:alerts_count],
    risk_score: portfolio_risk[:overall_risk][:score].round(1),
    recommendations_count: portfolio_risk[:recommendations]&.length || 0,
    last_updated: Time.now.strftime("%Y-%m-%d %H:%M:%S")
  }
  
  puts "Risk Dashboard:"
  puts "  Portfolio Health: #{RISK_LEVELS[dashboard[:portfolio_health].to_sym][:color]} #{dashboard[:portfolio_health]}"
  puts "  Risk Score: #{dashboard[:risk_score]}/5.0"
  puts "  Active Alerts: #{dashboard[:active_alerts]}"
  puts "  Pending Recommendations: #{dashboard[:recommendations_count]}"
  puts "  Last Updated: #{dashboard[:last_updated]}"
  
  # Health status
  overall_status = if dashboard[:risk_score] < 2.5 && dashboard[:active_alerts] == 0
    "🟢 HEALTHY"
  elsif dashboard[:risk_score] < 4.0 && dashboard[:active_alerts] < 3
    "🟡 CAUTION"
  else
    "🔴 HIGH RISK"
  end
  
  puts "  Overall Status: #{overall_status}"

rescue BudaApi::ApiError => e
  puts "❌ API Error: #{e.message}"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
end

# Define risk levels constant for display
RISK_LEVELS = {
  very_low: { color: "🟢", description: "Very Low Risk" },
  low: { color: "🟡", description: "Low Risk" },
  medium: { color: "🟠", description: "Medium Risk" },
  high: { color: "🔴", description: "High Risk" },
  very_high: { color: "🚫", description: "Very High Risk" }
}

if __FILE__ == $0
  main
end