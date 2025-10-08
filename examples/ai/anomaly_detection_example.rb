#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Market Anomaly Detection System
# This example demonstrates AI-powered anomaly detection for cryptocurrency markets

require 'bundler/setup'
require_relative '../../lib/buda_api'

# Configuration
API_KEY = ENV['BUDA_API_KEY'] || 'your_api_key_here'
API_SECRET = ENV['BUDA_API_SECRET'] || 'your_api_secret_here'

class AnomalyMonitor
  def initialize(client, llm_provider = :openai)
    @client = client
    @detector = BudaApi::AI::AnomalyDetector.new(client, llm_provider: llm_provider)
    @monitoring_active = false
    @alert_count = 0
  end
  
  def start_monitoring(markets = nil, options = {})
    markets ||= BudaApi::Constants::Market::MAJOR
    @monitoring_active = true
    @alert_count = 0
    
    puts "🔍 Starting Anomaly Detection System"
    puts "Markets: #{markets.join(', ')}"
    puts "=" * 50
    
    # Initial scan
    puts "\n📊 Initial Market Scan"
    puts "-" * 30
    
    initial_results = @detector.detect_market_anomalies(
      markets: markets,
      include_ai_analysis: true
    )
    
    display_detection_results(initial_results)
    
    # Set up continuous monitoring
    if options[:continuous]
      start_continuous_monitoring(markets, options[:interval] || 300)
    end
    
    # Set up alerts
    if options[:alerts]
      setup_alert_system(options[:alert_config] || {})
    end
  end
  
  def start_continuous_monitoring(markets, interval_seconds)
    puts "\n🔄 Starting Continuous Monitoring"
    puts "Scan interval: #{interval_seconds} seconds"
    puts "Press Ctrl+C to stop monitoring"
    puts "-" * 30
    
    begin
      while @monitoring_active
        sleep(interval_seconds)
        
        puts "\n⏰ #{Time.now.strftime('%H:%M:%S')} - Scanning markets..."
        
        results = @detector.detect_market_anomalies(
          markets: markets,
          include_ai_analysis: false  # Skip AI for frequent scans
        )
        
        if results[:anomalies_detected] > 0
          @alert_count += 1
          puts "🚨 ANOMALIES DETECTED (##{@alert_count})"
          display_detection_results(results, compact: true)
        else
          puts "✅ No anomalies detected"
        end
      end
    rescue Interrupt
      puts "\n⏹️ Monitoring stopped by user"
      @monitoring_active = false
    end
  end
  
  def setup_alert_system(config)
    puts "\n🚨 Setting up Alert System"
    puts "-" * 30
    
    alert_system = @detector.setup_anomaly_alerts(config)
    puts "Alert system configured: #{alert_system[:status]}"
    puts "Configuration: #{alert_system[:config]}"
    
    alert_system
  end
  
  def analyze_single_market(market_id)
    puts "\n🔍 Deep Market Analysis: #{market_id}"
    puts "-" * 30
    
    # Real-time analysis
    current_anomalies = @detector.detect_market_anomalies(
      markets: [market_id],
      include_ai_analysis: true
    )
    
    display_detection_results(current_anomalies)
    
    # Historical analysis
    puts "\n📈 Historical Anomaly Analysis (24h)"
    puts "-" * 30
    
    historical_results = @detector.analyze_historical_anomalies(market_id, 24)
    
    if historical_results[:type] == :historical_analysis
      puts "Data Points Analyzed: #{historical_results[:data_points]}"
      puts "Historical Anomalies: #{historical_results[:anomalies_found]}"
      
      if historical_results[:anomalies_found] > 0
        puts "\nTop Historical Anomalies:"
        historical_results[:anomalies].first(5).each_with_index do |anomaly, i|
          puts "#{i + 1}. #{anomaly[:type]}: #{anomaly[:description]} (#{anomaly[:severity]})"
        end
      end
    else
      puts "Historical analysis: #{historical_results[:message]}"
    end
  end
  
  def display_detection_results(results, compact: false)
    if results[:type] == :anomaly_detection_error
      puts "❌ Detection Error: #{results[:error]}"
      return
    end
    
    puts "Markets Analyzed: #{results[:markets_analyzed]}"
    puts "Anomalies Detected: #{results[:anomalies_detected]}"
    
    if results[:anomalies_detected] == 0
      puts "✅ All markets operating normally"
      return
    end
    
    # Display severity summary
    severity = results[:severity_summary]
    if severity[:critical] > 0 || severity[:high] > 0
      puts "🚨 Alert Levels:"
      puts "   Critical: #{severity[:critical]}" if severity[:critical] > 0
      puts "   High: #{severity[:high]}" if severity[:high] > 0
      puts "   Medium: #{severity[:medium]}" if severity[:medium] > 0
      puts "   Low: #{severity[:low]}" if severity[:low] > 0
    end
    
    # Display top anomalies
    display_count = compact ? 3 : 10
    puts "\n📋 Detected Anomalies:"
    
    results[:anomalies].first(display_count).each_with_index do |anomaly, i|
      severity_emoji = get_severity_emoji(anomaly[:severity])
      
      puts "#{i + 1}. #{severity_emoji} #{anomaly[:market_id]} - #{anomaly[:type].to_s.upcase}"
      puts "   #{anomaly[:description]}"
      puts "   Severity: #{anomaly[:severity]} (#{anomaly[:severity_score].round(1)})"
      
      unless compact
        if anomaly[:recommendation]
          puts "   💡 #{anomaly[:recommendation]}"
        end
        
        if anomaly[:details]
          display_anomaly_details(anomaly[:details])
        end
      end
      
      puts
    end
    
    # Display recommendations
    if results[:recommendations].any? && !compact
      puts "💡 General Recommendations:"
      results[:recommendations].each do |rec|
        puts "   • #{rec}"
      end
      puts
    end
    
    # Display AI analysis if available
    if results[:ai_analysis] && !compact
      puts "🧠 AI Analysis:"
      puts results[:ai_analysis][:analysis]
      puts
    end
  end
  
  def get_severity_emoji(severity)
    case severity
    when :critical then "🚫"
    when :high then "🔴"
    when :medium then "🟡"
    when :low then "🟢"
    else "❓"
    end
  end
  
  def display_anomaly_details(details)
    case
    when details[:current_price]
      puts "   Price: #{details[:current_price]} CLP"
      puts "   Change: #{details[:change_24h]}%" if details[:change_24h]
    when details[:current_volume]
      puts "   Volume: #{details[:current_volume]}"
      puts "   Ratio: #{details[:volume_ratio]}x normal" if details[:volume_ratio]
    when details[:current_spread]
      puts "   Spread: #{details[:current_spread]}%"
      puts "   Normal: #{details[:normal_spread]}%" if details[:normal_spread]
    when details[:large_orders]
      puts "   Large Orders: #{details[:large_orders].length}"
      puts "   Total Value: #{details[:total_value].round(2)} CLP" if details[:total_value]
    end
  end
  
  def generate_anomaly_report
    puts "\n📊 Anomaly Detection Report"
    puts "=" * 50
    
    # Generate comprehensive report
    markets = BudaApi::Constants::Market::MAJOR
    
    full_results = @detector.detect_market_anomalies(
      markets: markets,
      include_ai_analysis: true
    )
    
    display_detection_results(full_results)
    
    # Save report to file
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    filename = "anomaly_report_#{timestamp}.json"
    
    File.write(filename, JSON.pretty_generate(full_results))
    puts "📄 Full report saved to: #{filename}"
    
    full_results
  end
end

def main
  puts "🔍 Market Anomaly Detection System"
  puts "=" * 50
  
  unless BudaApi.ai_available?
    puts "❌ AI features not available. Install ruby_llm gem first."
    return
  end
  
  # Initialize client and monitor
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true
  )
  
  monitor = AnomalyMonitor.new(client, :openai)
  
  puts "Select monitoring mode:"
  puts "1. One-time scan (default)"
  puts "2. Continuous monitoring"
  puts "3. Single market analysis" 
  puts "4. Generate full report"
  print "Choice (1-4): "
  
  choice = gets.chomp
  
  case choice
  when '2'
    # Continuous monitoring
    puts "\nContinuous monitoring setup:"
    print "Scan interval (seconds, default 300): "
    interval = gets.chomp.to_i
    interval = 300 if interval <= 0
    
    monitor.start_monitoring(
      nil,  # Use default markets
      continuous: true,
      interval: interval,
      alerts: true
    )
    
  when '3'
    # Single market analysis
    puts "\nAvailable markets: #{BudaApi::Constants::Market::MAJOR.join(', ')}"
    print "Enter market ID (e.g., BTC-CLP): "
    market_id = gets.chomp.upcase
    
    if BudaApi::Constants::Market::MAJOR.include?(market_id)
      monitor.analyze_single_market(market_id)
    else
      puts "❌ Invalid market ID"
    end
    
  when '4'
    # Generate full report
    monitor.generate_anomaly_report
    
  else
    # One-time scan (default)
    monitor.start_monitoring(
      BudaApi::Constants::Market::MAJOR,
      continuous: false
    )
  end
  
rescue BudaApi::ApiError => e
  puts "❌ API Error: #{e.message}"
rescue Interrupt
  puts "\n⏹️ Monitoring stopped"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
end

def demo_mode
  puts "\n🎭 Demo Mode - Simulated Anomaly Detection"
  puts "=" * 50
  
  # Simulate some anomalies for demonstration
  simulated_anomalies = [
    {
      type: :price_spike,
      market_id: "BTC-CLP",
      severity: :high,
      severity_score: 8.2,
      description: "Price spike detected: +12.5% change",
      recommendation: "Monitor for potential reversal or continuation",
      timestamp: Time.now
    },
    {
      type: :volume_anomaly,
      market_id: "ETH-CLP", 
      severity: :medium,
      severity_score: 6.1,
      description: "Volume anomaly: 4.2x normal volume",
      recommendation: "Watch for breaking news or large transactions",
      timestamp: Time.now
    },
    {
      type: :whale_activity,
      market_id: "BTC-CLP",
      severity: :high,
      severity_score: 7.8,
      description: "Large order activity detected: 3 whale orders",
      recommendation: "Expect potential price impact from large orders",
      timestamp: Time.now
    }
  ]
  
  simulated_results = {
    type: :anomaly_detection,
    timestamp: Time.now,
    markets_analyzed: 3,
    anomalies_detected: 3,
    anomalies: simulated_anomalies,
    severity_summary: { critical: 0, high: 2, medium: 1, low: 0 },
    recommendations: [
      "🚨 Multiple high-severity anomalies detected",
      "🐋 Large order activity - monitor for price impact",
      "📊 Increased market volatility - use caution with orders"
    ]
  }
  
  puts "📊 Simulated Detection Results:"
  
  monitor = Object.new
  monitor.define_singleton_method(:display_detection_results) do |results, compact: false|
    # Use the same display logic as the real monitor
    puts "Markets Analyzed: #{results[:markets_analyzed]}"
    puts "Anomalies Detected: #{results[:anomalies_detected]}"
    
    puts "\n🚨 Alert Levels:"
    severity = results[:severity_summary]
    puts "   High: #{severity[:high]}" if severity[:high] > 0
    puts "   Medium: #{severity[:medium]}" if severity[:medium] > 0
    
    puts "\n📋 Detected Anomalies:"
    results[:anomalies].each_with_index do |anomaly, i|
      severity_emoji = case anomaly[:severity]
        when :high then "🔴"
        when :medium then "🟡"
        else "🟢"
      end
      
      puts "#{i + 1}. #{severity_emoji} #{anomaly[:market_id]} - #{anomaly[:type].to_s.upcase}"
      puts "   #{anomaly[:description]}"
      puts "   💡 #{anomaly[:recommendation]}"
      puts
    end
    
    puts "💡 Recommendations:"
    results[:recommendations].each { |rec| puts "   • #{rec}" }
  end
  
  monitor.display_detection_results(simulated_results)
  
  puts "\n🎯 This is a demonstration of the anomaly detection system."
  puts "In real mode, it would analyze actual market data from the Buda API."
end

if __FILE__ == $0
  if ARGV.include?('--demo')
    demo_mode
  else
    main
  end
end