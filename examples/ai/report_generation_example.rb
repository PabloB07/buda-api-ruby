#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: AI-Powered Report Generation
# This example demonstrates automated report generation with AI analysis

require 'bundler/setup'
require_relative '../../lib/buda_api'

# Configuration
API_KEY = ENV['BUDA_API_KEY'] || 'your_api_key_here'
API_SECRET = ENV['BUDA_API_SECRET'] || 'your_api_secret_here'

class ReportingDashboard
  def initialize(client, llm_provider = :openai)
    @client = client
    @reporter = BudaApi::AI::ReportGenerator.new(client, llm_provider: llm_provider)
  end
  
  def show_main_menu
    puts "\n📊 AI Report Generation Dashboard"
    puts "=" * 50
    puts "1. Portfolio Summary Report"
    puts "2. Trading Performance Report" 
    puts "3. Market Analysis Report"
    puts "4. Custom AI Report"
    puts "5. Risk Assessment Report"
    puts "6. Generate All Reports"
    puts "7. Export Reports"
    puts "0. Exit"
    puts "-" * 50
    print "Select option (0-7): "
    
    choice = gets.chomp
    
    case choice
    when '1' then generate_portfolio_summary
    when '2' then generate_trading_performance
    when '3' then generate_market_analysis
    when '4' then generate_custom_report
    when '5' then generate_risk_assessment
    when '6' then generate_all_reports
    when '7' then export_reports_menu
    when '0' then exit_dashboard
    else
      puts "Invalid option. Please try again."
      show_main_menu
    end
  end
  
  def generate_portfolio_summary
    puts "\n💰 Generating Portfolio Summary Report..."
    puts "-" * 40
    
    # Get format preference
    format = select_report_format
    
    report = @reporter.generate_portfolio_summary(
      format: format,
      include_ai: true
    )
    
    if report[:type] == :portfolio_summary_report
      display_portfolio_report(report)
      @last_report = report
    else
      puts "❌ #{report[:error] || report[:message]}"
    end
    
    pause_and_return
  end
  
  def generate_trading_performance
    puts "\n📈 Generating Trading Performance Report..."
    puts "-" * 40
    
    # Get market selection
    puts "Select market:"
    puts "1. All markets (default)"
    puts "2. BTC-CLP only"
    puts "3. ETH-CLP only"
    puts "4. Custom market"
    print "Choice (1-4): "
    
    choice = gets.chomp
    market_id = case choice
      when '2' then 'BTC-CLP'
      when '3' then 'ETH-CLP'
      when '4'
        print "Enter market ID: "
        gets.chomp.upcase
      else
        'all'
    end
    
    format = select_report_format
    
    report = @reporter.generate_trading_performance(
      market_id,
      format: format,
      limit: 50,
      include_ai: true
    )
    
    if report[:type] == :trading_performance_report
      display_trading_report(report)
      @last_report = report
    else
      puts "❌ #{report[:error] || report[:message]}"
    end
    
    pause_and_return
  end
  
  def generate_market_analysis
    puts "\n📊 Generating Market Analysis Report..."
    puts "-" * 40
    
    markets = BudaApi::Constants::Market::MAJOR
    format = select_report_format
    
    report = @reporter.generate_market_analysis(
      markets,
      format: format,
      include_ai: true
    )
    
    if report[:type] == :market_analysis_report
      display_market_report(report)
      @last_report = report
    else
      puts "❌ #{report[:error] || report[:message]}"
    end
    
    pause_and_return
  end
  
  def generate_custom_report
    puts "\n🧠 Custom AI Report Generation"
    puts "-" * 40
    
    puts "What would you like me to analyze and report on?"
    puts "Example prompts:"
    puts "• 'Analyze my portfolio diversification and suggest improvements'"
    puts "• 'Compare Bitcoin and Ethereum performance this week'"
    puts "• 'Generate investment recommendations for Chilean market'"
    puts "• 'Assess current market volatility and risks'"
    puts
    print "Your custom prompt: "
    
    prompt = gets.chomp
    
    if prompt.strip.empty?
      puts "❌ Please provide a prompt for the custom report"
      return generate_custom_report
    end
    
    # Select data sources
    puts "\nWhat data should I include?"
    puts "1. Portfolio only"
    puts "2. Market data only" 
    puts "3. Trading history only"
    puts "4. All available data (default)"
    print "Choice (1-4): "
    
    choice = gets.chomp
    data_sources = case choice
      when '1' then [:portfolio]
      when '2' then [:market]
      when '3' then [:trades]
      else [:portfolio, :market, :trades]
    end
    
    format = select_report_format
    
    puts "\n🤖 Generating custom analysis..."
    
    report = @reporter.generate_custom_report(
      prompt,
      data_sources,
      format: format
    )
    
    if report[:type] == :custom_report
      display_custom_report(report)
      @last_report = report
    else
      puts "❌ #{report[:error] || report[:message]}"
    end
    
    pause_and_return
  end
  
  def generate_risk_assessment
    puts "\n⚠️ Generating Risk Assessment Report..."
    puts "-" * 40
    
    # Use risk manager for comprehensive risk analysis
    risk_manager = BudaApi::AI::RiskManager.new(@client)
    
    risk_analysis = risk_manager.analyze_portfolio_risk(include_ai_insights: true)
    
    if risk_analysis[:type] == :portfolio_risk_analysis
      display_risk_report(risk_analysis)
      
      # Convert to report format
      @last_report = {
        type: :risk_assessment_report,
        format: "text",
        data: risk_analysis,
        timestamp: Time.now
      }
    else
      puts "❌ #{risk_analysis[:error] || risk_analysis[:message]}"
    end
    
    pause_and_return
  end
  
  def generate_all_reports
    puts "\n📋 Generating Complete Report Suite..."
    puts "=" * 50
    
    reports = {}
    
    # Generate each report type
    report_types = [
      { name: "Portfolio Summary", method: :generate_portfolio_summary_silent },
      { name: "Trading Performance", method: :generate_trading_performance_silent },
      { name: "Market Analysis", method: :generate_market_analysis_silent }
    ]
    
    report_types.each do |report_type|
      puts "📊 Generating #{report_type[:name]}..."
      
      begin
        report = send(report_type[:method])
        reports[report_type[:name]] = report
        puts "   ✅ Complete"
      rescue => e
        puts "   ❌ Failed: #{e.message}"
      end
    end
    
    # Display summary
    puts "\n📋 Report Generation Summary"
    puts "-" * 30
    
    reports.each do |name, report|
      status = report && report[:formatted_content] ? "✅" : "❌"
      puts "#{status} #{name}"
    end
    
    # Save all reports
    if reports.any?
      puts "\n💾 Saving reports to files..."
      save_all_reports(reports)
    end
    
    pause_and_return
  end
  
  def export_reports_menu
    unless @last_report
      puts "❌ No report available to export. Generate a report first."
      return pause_and_return
    end
    
    puts "\n💾 Export Report"
    puts "-" * 20
    puts "Current report: #{@last_report[:type]}"
    puts "Current format: #{@last_report[:format]}"
    puts
    puts "Export options:"
    puts "1. Save current format"
    puts "2. Export as Markdown"
    puts "3. Export as HTML"
    puts "4. Export as JSON"
    puts "5. Export as CSV"
    print "Choice (1-5): "
    
    choice = gets.chomp
    
    export_format = case choice
      when '2' then 'markdown'
      when '3' then 'html'
      when '4' then 'json'
      when '5' then 'csv'
      else @last_report[:format]
    end
    
    # Generate filename
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    report_type = @last_report[:type].to_s.gsub('_report', '').gsub('_', '-')
    extension = get_file_extension(export_format)
    filename = "buda-#{report_type}-#{timestamp}.#{extension}"
    
    # Export report
    export_result = @reporter.export_report(@last_report, filename)
    
    if export_result[:type] == :export_success
      puts "✅ Report exported successfully!"
      puts "   File: #{export_result[:filename]}"
      puts "   Size: #{export_result[:size]} bytes"
      puts "   Format: #{export_result[:format]}"
    else
      puts "❌ Export failed: #{export_result[:error]}"
    end
    
    pause_and_return
  end
  
  def exit_dashboard
    puts "\n👋 Goodbye! Happy trading!"
    exit
  end
  
  private
  
  def select_report_format
    puts "\nSelect report format:"
    puts "1. Markdown (default)"
    puts "2. Plain text"
    puts "3. HTML"
    puts "4. JSON"
    print "Choice (1-4): "
    
    choice = gets.chomp
    
    case choice
    when '2' then 'text'
    when '3' then 'html'
    when '4' then 'json'
    else 'markdown'
    end
  end
  
  def display_portfolio_report(report)
    puts "\n💰 Portfolio Summary Report"
    puts "=" * 40
    puts "Generated: #{report[:data][:generated_at]}"
    
    if report[:data][:summary]
      summary = report[:data][:summary]
      puts "Total Value: #{summary[:total_value].round(2)} CLP"
      puts "Assets: #{summary[:asset_count]}"
      puts "24h Change: #{summary[:total_change_24h].round(2)}%" if summary[:total_change_24h]
      puts "Top Holding: #{summary[:top_holding]}" if summary[:top_holding]
    end
    
    # Show formatted content (first 500 chars)
    if report[:formatted_content]
      puts "\nReport Preview:"
      puts "-" * 20
      content_preview = report[:formatted_content][0, 500]
      content_preview += "..." if report[:formatted_content].length > 500
      puts content_preview
    end
  end
  
  def display_trading_report(report)
    puts "\n📈 Trading Performance Report"  
    puts "=" * 40
    puts "Generated: #{report[:data][:generated_at]}"
    puts "Market: #{report[:data][:market_id]}"
    
    if report[:data][:performance]
      perf = report[:data][:performance]
      puts "Total Trades: #{perf[:total_trades]}"
      puts "Win Rate: #{perf[:win_rate].round(1)}%"
      puts "Total Volume: #{perf[:total_volume].round(2)} CLP"
      puts "Total Fees: #{perf[:total_fees].round(2)} CLP"
    end
    
    # Show AI insights if available
    if report[:data][:ai_insights]
      puts "\n🧠 AI Insights:"
      puts report[:data][:ai_insights][:content]
    end
  end
  
  def display_market_report(report)
    puts "\n📊 Market Analysis Report"
    puts "=" * 40
    puts "Generated: #{report[:data][:generated_at]}"
    puts "Markets: #{report[:data][:markets_analyzed]}"
    
    if report[:data][:summary]
      summary = report[:data][:summary]
      puts "Markets Up: #{summary[:markets_up]}"
      puts "Markets Down: #{summary[:markets_down]}"
      puts "Sentiment: #{summary[:market_sentiment]}"
    end
    
    if report[:data][:ai_insights]
      puts "\n🧠 AI Market Insights:"
      puts report[:data][:ai_insights][:content]
    end
  end
  
  def display_custom_report(report)
    puts "\n🧠 Custom AI Report"
    puts "=" * 40
    puts "Generated: #{report[:data][:generated_at]}"
    puts "Prompt: #{report[:data][:prompt]}"
    puts "Data Sources: #{report[:data][:data_sources].join(', ')}"
    
    if report[:data][:ai_analysis]
      puts "\n📋 AI Analysis:"
      puts report[:data][:ai_analysis][:content]
    end
  end
  
  def display_risk_report(risk_analysis)
    puts "\n⚠️ Portfolio Risk Assessment"
    puts "=" * 40
    puts "Generated: #{risk_analysis[:timestamp]}"
    puts "Portfolio Value: #{risk_analysis[:portfolio_value].round(2)} CLP"
    puts "Risk Level: #{risk_analysis[:overall_risk][:color]} #{risk_analysis[:overall_risk][:level]}"
    puts "Risk Score: #{risk_analysis[:overall_risk][:score].round(1)}/5.0"
    
    if risk_analysis[:recommendations].any?
      puts "\nRecommendations:"
      risk_analysis[:recommendations].each do |rec|
        puts "• #{rec[:message]}"
      end
    end
    
    if risk_analysis[:ai_insights]
      puts "\n🧠 AI Risk Insights:"
      puts risk_analysis[:ai_insights][:analysis]
    end
  end
  
  def generate_portfolio_summary_silent
    @reporter.generate_portfolio_summary(format: "markdown", include_ai: true)
  end
  
  def generate_trading_performance_silent  
    @reporter.generate_trading_performance('all', format: "markdown", include_ai: true)
  end
  
  def generate_market_analysis_silent
    @reporter.generate_market_analysis(BudaApi::Constants::Market::MAJOR, format: "markdown", include_ai: true)
  end
  
  def save_all_reports(reports)
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    
    reports.each do |name, report|
      next unless report && report[:formatted_content]
      
      filename = "buda-#{name.downcase.gsub(' ', '-')}-#{timestamp}.md"
      File.write(filename, report[:formatted_content])
      puts "   💾 #{filename}"
    end
    
    puts "✅ All reports saved successfully!"
  end
  
  def get_file_extension(format)
    case format
    when 'markdown' then 'md'
    when 'html' then 'html'
    when 'json' then 'json'
    when 'csv' then 'csv'
    else 'txt'
    end
  end
  
  def pause_and_return
    puts "\nPress Enter to return to main menu..."
    gets
    show_main_menu
  end
end

def main
  puts "📊 AI Report Generation System"
  puts "=" * 50
  
  unless BudaApi.ai_available?
    puts "❌ AI features not available. Install ruby_llm gem first."
    return
  end
  
  # Initialize client and dashboard
  client = BudaApi::AuthenticatedClient.new(
    api_key: API_KEY,
    api_secret: API_SECRET,
    sandbox: true
  )
  
  dashboard = ReportingDashboard.new(client, :openai)
  dashboard.show_main_menu
  
rescue BudaApi::ApiError => e
  puts "❌ API Error: #{e.message}"
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace.first(3).join("\n") if ENV['DEBUG']
end

def demo_reports
  puts "\n🎭 Demo Report Generation"
  puts "=" * 50
  
  # Generate sample reports with mock data
  reports = {
    "Portfolio Summary" => generate_demo_portfolio_report,
    "Market Analysis" => generate_demo_market_report,
    "Trading Performance" => generate_demo_trading_report
  }
  
  reports.each do |name, content|
    filename = "demo-#{name.downcase.gsub(' ', '-')}.md"
    File.write(filename, content)
    puts "📄 Generated: #{filename}"
  end
  
  puts "\n✅ Demo reports generated successfully!"
  puts "These reports show the format and structure of AI-generated content."
end

def generate_demo_portfolio_report
  """# Portfolio Summary Report
*Generated: #{Time.now}*

## Overview
- **Total Portfolio Value:** 2,500,000 CLP
- **Number of Assets:** 4
- **24h Change:** +3.2% (+80,000 CLP)

## Holdings
| Asset | Amount | Value (CLP) | Allocation |
|-------|---------|-------------|------------|
| BTC | 0.0125 | 1,250,000 | 50.0% |
| ETH | 0.75 | 750,000 | 30.0% |
| CLP | 400,000 | 400,000 | 16.0% |
| USDC | 100 | 100,000 | 4.0% |

## Market Performance
| Market | Price | 24h Change | Volume |
|--------|-------|------------|--------|
| BTC-CLP | 100,000,000 | +2.5% | 15,000,000 |
| ETH-CLP | 1,000,000 | +4.1% | 8,500,000 |

## AI Analysis
Your portfolio shows strong performance with a healthy 3.2% gain over 24 hours. The 50% Bitcoin allocation provides good stability, while the 30% Ethereum position offers growth potential. Consider reducing the high concentration in BTC by diversifying into other cryptocurrencies. The 16% CLP position provides good liquidity for opportunities. Overall risk level is moderate with good upside potential in the current market conditions.
"""
end

def generate_demo_market_report
  """# Market Analysis Report
*Generated: #{Time.now}*

## Market Overview
- **Markets Analyzed:** 5
- **Overall Sentiment:** Bullish
- **Markets Up:** 4
- **Markets Down:** 1

## Performance Summary
| Market | Current Price | 24h Change | Volume | Status |
|--------|---------------|------------|---------|---------|
| BTC-CLP | 100,000,000 | +2.5% | 15M | 🟢 Strong |
| ETH-CLP | 1,000,000 | +4.1% | 8.5M | 🟢 Very Strong |
| LTC-CLP | 150,000 | +1.8% | 2.1M | 🟢 Moderate |
| BCH-CLP | 500,000 | -0.5% | 1.8M | 🔴 Weak |

## AI Market Insights
The Chilean cryptocurrency market is showing strong bullish momentum with 80% of major pairs posting gains. Bitcoin's 2.5% increase demonstrates solid institutional confidence, while Ethereum's 4.1% surge indicates strong DeFi activity. Trading volumes are above average, suggesting healthy market participation. The slight weakness in Bitcoin Cash appears to be profit-taking rather than fundamental concerns. Recommend maintaining long positions with trailing stops to capture continued upside while protecting against potential reversals.
"""
end

def generate_demo_trading_report
  """# Trading Performance Report
*Generated: #{Time.now}*

## Performance Summary
- **Total Trades:** 25
- **Winning Trades:** 16 (64%)
- **Total Volume:** 12,500,000 CLP
- **Total Fees:** 25,000 CLP
- **Net P&L:** +125,000 CLP (+1.0%)

## Trading Breakdown
| Market | Trades | Win Rate | Volume | P&L |
|---------|---------|----------|---------|------|
| BTC-CLP | 15 | 67% | 8,000,000 | +85,000 |
| ETH-CLP | 8 | 63% | 3,500,000 | +35,000 |
| LTC-CLP | 2 | 50% | 1,000,000 | +5,000 |

## AI Trading Insights
Your trading performance shows solid discipline with a 64% win rate and positive returns. The focus on BTC-CLP demonstrates good market selection, with your best performance coming from the most liquid market. Consider reducing position sizes on lower-volume markets like LTC-CLP to minimize slippage impact. The fee ratio of 0.2% is reasonable but could be optimized by using more limit orders instead of market orders. Overall strategy appears sound with room for improvement in risk management and position sizing.
"""
end

if __FILE__ == $0
  if ARGV.include?('--demo')
    demo_reports
  else
    main
  end
end