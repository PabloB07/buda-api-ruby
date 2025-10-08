# frozen_string_literal: true

module BudaApi
  module AI
    # AI-powered report generation for trading analysis
    class ReportGenerator
      REPORT_TYPES = %w[
        portfolio_summary
        trading_performance
        market_analysis
        risk_assessment
        profit_loss
        tax_report
        custom
      ].freeze

      EXPORT_FORMATS = %w[text markdown html json csv].freeze

      def initialize(client, llm_provider: :openai)
        @client = client
        @llm = RubyLLM.new(
          provider: llm_provider,
          system_prompt: build_report_system_prompt
        )
        
        BudaApi::Logger.info("Report Generator initialized")
      end

      # Generate comprehensive portfolio summary report
      #
      # @param options [Hash] report options
      # @option options [String] :format export format (text, markdown, html, json, csv)
      # @option options [Boolean] :include_charts include visual elements
      # @option options [Date] :start_date analysis start date
      # @option options [Date] :end_date analysis end date
      # @return [Hash] generated report
      def generate_portfolio_summary(options = {})
        format = options[:format] || "markdown"
        include_ai = options[:include_ai] != false
        
        BudaApi::Logger.info("Generating portfolio summary report")
        
        begin
          # Gather portfolio data
          balances_result = @client.balances
          portfolios = extract_portfolio_data(balances_result)
          
          return empty_portfolio_report(format) if portfolios.empty?
          
          # Get market data
          market_data = fetch_portfolio_market_data(portfolios)
          
          # Calculate metrics
          portfolio_metrics = calculate_portfolio_metrics(portfolios, market_data)
          
          # Generate base report
          report_data = {
            type: :portfolio_summary,
            generated_at: Time.now,
            portfolio: portfolios,
            market_data: market_data,
            metrics: portfolio_metrics,
            summary: {
              total_value: portfolio_metrics[:total_value_clp],
              asset_count: portfolios.length,
              top_holding: portfolio_metrics[:top_holding],
              total_change_24h: portfolio_metrics[:total_change_24h]
            }
          }
          
          # Add AI analysis if requested
          if include_ai
            report_data[:ai_analysis] = generate_ai_portfolio_analysis(report_data)
          end
          
          # Format the report
          formatted_report = format_report(report_data, format)
          
          {
            type: :portfolio_summary_report,
            format: format,
            data: report_data,
            formatted_content: formatted_report,
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Portfolio summary generation failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :report_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Generate trading performance report
      #
      # @param market_id [String] specific market or 'all'
      # @param options [Hash] report options
      # @return [Hash] trading performance report
      def generate_trading_performance(market_id = 'all', options = {})
        format = options[:format] || "markdown"
        limit = options[:limit] || 50
        include_ai = options[:include_ai] != false
        
        BudaApi::Logger.info("Generating trading performance report for #{market_id}")
        
        begin
          # Get trading history
          trading_data = fetch_trading_history(market_id, limit)
          
          return empty_trading_report(format) if trading_data.empty?
          
          # Calculate performance metrics
          performance_metrics = calculate_performance_metrics(trading_data)
          
          # Generate report data
          report_data = {
            type: :trading_performance,
            generated_at: Time.now,
            market_id: market_id,
            period: {
              trades_analyzed: trading_data.length,
              date_range: get_date_range(trading_data)
            },
            trades: trading_data,
            performance: performance_metrics
          }
          
          # Add AI insights
          if include_ai
            report_data[:ai_insights] = generate_ai_trading_insights(report_data)
          end
          
          # Format report
          formatted_report = format_report(report_data, format)
          
          {
            type: :trading_performance_report,
            format: format,
            data: report_data,
            formatted_content: formatted_report,
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Trading performance report failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :report_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Generate market analysis report
      #
      # @param markets [Array<String>] markets to analyze
      # @param options [Hash] report options
      # @return [Hash] market analysis report
      def generate_market_analysis(markets = nil, options = {})
        markets ||= BudaApi::Constants::Market::MAJOR
        format = options[:format] || "markdown"
        include_ai = options[:include_ai] != false
        
        BudaApi::Logger.info("Generating market analysis report for #{markets.length} markets")
        
        begin
          # Gather market data
          market_analysis = {}
          
          markets.each do |market_id|
            market_analysis[market_id] = analyze_single_market(market_id)
          end
          
          # Calculate cross-market metrics
          market_metrics = calculate_market_metrics(market_analysis)
          
          # Generate report data
          report_data = {
            type: :market_analysis,
            generated_at: Time.now,
            markets_analyzed: markets.length,
            markets: market_analysis,
            metrics: market_metrics,
            summary: generate_market_summary(market_analysis, market_metrics)
          }
          
          # Add AI market insights
          if include_ai
            report_data[:ai_insights] = generate_ai_market_insights(report_data)
          end
          
          # Format report
          formatted_report = format_report(report_data, format)
          
          {
            type: :market_analysis_report,
            format: format,
            data: report_data,
            formatted_content: formatted_report,
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Market analysis report failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :report_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Generate custom report with AI assistance
      #
      # @param prompt [String] custom report requirements
      # @param data_sources [Array<Symbol>] data to include (:portfolio, :trades, :market)
      # @param options [Hash] report options
      # @return [Hash] custom report
      def generate_custom_report(prompt, data_sources = [:portfolio], options = {})
        format = options[:format] || "markdown"
        
        BudaApi::Logger.info("Generating custom report: #{prompt}")
        
        begin
          # Gather requested data
          gathered_data = {}
          
          if data_sources.include?(:portfolio)
            balances_result = @client.balances
            gathered_data[:portfolio] = extract_portfolio_data(balances_result)
          end
          
          if data_sources.include?(:trades)
            gathered_data[:trades] = fetch_recent_trades_all_markets
          end
          
          if data_sources.include?(:market)
            gathered_data[:market] = fetch_market_overview
          end
          
          # Generate AI report
          ai_report = generate_ai_custom_report(prompt, gathered_data)
          
          # Structure report data
          report_data = {
            type: :custom_report,
            generated_at: Time.now,
            prompt: prompt,
            data_sources: data_sources,
            data: gathered_data,
            ai_analysis: ai_report
          }
          
          # Format report
          formatted_report = format_report(report_data, format)
          
          {
            type: :custom_report,
            format: format,
            data: report_data,
            formatted_content: formatted_report,
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Custom report generation failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :report_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Export report to file
      #
      # @param report [Hash] generated report
      # @param filename [String] output filename
      # @return [Hash] export result
      def export_report(report, filename = nil)
        filename ||= generate_filename(report)
        
        begin
          case report[:format]
          when "json"
            write_json_report(report, filename)
          when "csv"
            write_csv_report(report, filename)
          when "html"
            write_html_report(report, filename)
          else
            write_text_report(report, filename)
          end
          
          {
            type: :export_success,
            filename: filename,
            format: report[:format],
            size: File.size(filename),
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Report export failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :export_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      private

      def build_report_system_prompt
        """
        You are an expert cryptocurrency trading analyst and report writer.
        
        Your expertise includes:
        - Portfolio performance analysis
        - Market trend identification
        - Risk assessment and recommendations
        - Profit/loss analysis
        - Trading strategy evaluation
        - Chilean cryptocurrency market knowledge
        
        When generating reports:
        1. Use clear, professional language
        2. Provide specific, data-driven insights
        3. Include actionable recommendations
        4. Highlight both opportunities and risks
        5. Consider Chilean market conditions and regulations
        6. Use appropriate financial terminology
        7. Structure information logically with headings and bullet points
        
        Always base conclusions on the provided data and clearly state assumptions.
        """
      end

      def extract_portfolio_data(balances_result)
        balances_result.balances.select do |balance|
          balance.amount.amount > 0.0001
        end.map do |balance|
          {
            currency: balance.currency,
            amount: balance.amount.amount,
            available: balance.available_amount.amount,
            frozen: balance.frozen_amount.amount
          }
        end
      end

      def fetch_portfolio_market_data(portfolios)
        market_data = {}
        
        portfolios.each do |holding|
          currency = holding[:currency]
          next if currency == "CLP"
          
          market_id = "#{currency}-CLP"
          begin
            ticker = @client.ticker(market_id)
            market_data[currency] = {
              market_id: market_id,
              price: ticker.last_price.amount,
              change_24h: ticker.price_variation_24h,
              volume: ticker.volume.amount,
              min_24h: ticker.min_24h.amount,
              max_24h: ticker.max_24h.amount
            }
          rescue => e
            BudaApi::Logger.warn("Could not fetch market data for #{market_id}: #{e.message}")
          end
        end
        
        market_data
      end

      def calculate_portfolio_metrics(portfolios, market_data)
        total_value_clp = 0.0
        total_change_24h = 0.0
        top_holding = { currency: nil, value: 0.0, percentage: 0.0 }
        
        # Calculate values and changes
        portfolios.each do |holding|
          currency = holding[:currency]
          
          if currency == "CLP"
            value_clp = holding[:amount]
            change_24h_clp = 0.0
          elsif market_data[currency]
            value_clp = holding[:amount] * market_data[currency][:price]
            change_24h_clp = value_clp * (market_data[currency][:change_24h] / 100.0)
          else
            value_clp = 0.0
            change_24h_clp = 0.0
          end
          
          total_value_clp += value_clp
          total_change_24h += change_24h_clp
          
          # Track top holding
          if value_clp > top_holding[:value]
            top_holding = {
              currency: currency,
              value: value_clp,
              amount: holding[:amount]
            }
          end
        end
        
        # Calculate percentages
        if total_value_clp > 0
          top_holding[:percentage] = (top_holding[:value] / total_value_clp) * 100
          total_change_24h_percent = (total_change_24h / total_value_clp) * 100
        else
          total_change_24h_percent = 0.0
        end
        
        {
          total_value_clp: total_value_clp,
          total_change_24h: total_change_24h,
          total_change_24h_percent: total_change_24h_percent,
          top_holding: top_holding,
          asset_allocation: calculate_asset_allocation(portfolios, market_data, total_value_clp)
        }
      end

      def calculate_asset_allocation(portfolios, market_data, total_value)
        return {} if total_value <= 0
        
        allocation = {}
        
        portfolios.each do |holding|
          currency = holding[:currency]
          
          if currency == "CLP"
            value = holding[:amount]
          elsif market_data[currency]
            value = holding[:amount] * market_data[currency][:price]
          else
            value = 0.0
          end
          
          percentage = (value / total_value) * 100
          allocation[currency] = {
            amount: holding[:amount],
            value_clp: value,
            percentage: percentage
          }
        end
        
        allocation.sort_by { |_, data| -data[:percentage] }.to_h
      end

      def fetch_trading_history(market_id, limit)
        trades = []
        
        if market_id == 'all'
          # Get trades from all available markets
          BudaApi::Constants::Market::MAJOR.each do |market|
            begin
              market_trades = @client.orders(market, per_page: [limit / 4, 10].max)
              trades.concat(extract_trade_data(market_trades.orders, market))
            rescue => e
              BudaApi::Logger.warn("Could not fetch trades for #{market}: #{e.message}")
            end
          end
        else
          begin
            orders_result = @client.orders(market_id, per_page: limit)
            trades = extract_trade_data(orders_result.orders, market_id)
          rescue => e
            BudaApi::Logger.warn("Could not fetch trades for #{market_id}: #{e.message}")
          end
        end
        
        trades.sort_by { |trade| trade[:created_at] }.reverse
      end

      def extract_trade_data(orders, market_id)
        orders.select { |order| order.state == "traded" }.map do |order|
          {
            id: order.id,
            market_id: market_id,
            side: order.type.downcase,
            amount: order.amount.amount,
            price: order.limit&.amount || order.price&.amount,
            total: order.total_exchanged&.amount,
            fee: order.fee&.amount,
            created_at: order.created_at,
            state: order.state
          }
        end
      end

      def calculate_performance_metrics(trades)
        return empty_performance_metrics if trades.empty?
        
        total_trades = trades.length
        buy_trades = trades.select { |t| t[:side] == "bid" }
        sell_trades = trades.select { |t| t[:side] == "ask" }
        
        total_volume = trades.sum { |t| t[:total] || 0 }
        total_fees = trades.sum { |t| t[:fee] || 0 }
        
        # Calculate average trade sizes
        avg_trade_size = total_volume / total_trades if total_trades > 0
        
        # Calculate win rate (simplified)
        profitable_trades = estimate_profitable_trades(trades)
        win_rate = total_trades > 0 ? (profitable_trades / total_trades.to_f) * 100 : 0
        
        {
          total_trades: total_trades,
          buy_trades: buy_trades.length,
          sell_trades: sell_trades.length,
          total_volume: total_volume,
          total_fees: total_fees,
          avg_trade_size: avg_trade_size,
          win_rate: win_rate,
          trading_frequency: calculate_trading_frequency(trades),
          most_traded_market: find_most_traded_market(trades)
        }
      end

      def estimate_profitable_trades(trades)
        # Simplified profitability estimation
        # In a real implementation, this would track buy/sell pairs
        profitable = 0
        
        trades.each_with_index do |trade, index|
          next if index == 0
          
          prev_trade = trades[index - 1]
          if trade[:market_id] == prev_trade[:market_id]
            # Simple check: if price increased between buy and sell
            if prev_trade[:side] == "bid" && trade[:side] == "ask"
              profitable += 1 if trade[:price] > prev_trade[:price]
            end
          end
        end
        
        profitable
      end

      def calculate_trading_frequency(trades)
        return 0 if trades.length < 2
        
        first_trade = trades.last[:created_at]
        last_trade = trades.first[:created_at]
        
        days_span = (Time.parse(last_trade) - Time.parse(first_trade)) / (24 * 60 * 60)
        return 0 if days_span <= 0
        
        trades.length / days_span.to_f
      end

      def find_most_traded_market(trades)
        market_counts = trades.group_by { |t| t[:market_id] }.transform_values(&:length)
        market_counts.max_by { |_, count| count }&.first || "N/A"
      end

      def analyze_single_market(market_id)
        begin
          ticker = @client.ticker(market_id)
          order_book = @client.order_book(market_id)
          
          {
            market_id: market_id,
            price: ticker.last_price.amount,
            change_24h: ticker.price_variation_24h,
            volume: ticker.volume.amount,
            min_24h: ticker.min_24h.amount,
            max_24h: ticker.max_24h.amount,
            spread: calculate_spread(order_book),
            order_book_depth: analyze_order_book_depth(order_book)
          }
        rescue => e
          BudaApi::Logger.warn("Could not analyze market #{market_id}: #{e.message}")
          {
            market_id: market_id,
            error: e.message
          }
        end
      end

      def calculate_spread(order_book)
        return 0 if order_book.asks.empty? || order_book.bids.empty?
        
        best_ask = order_book.asks.first.price
        best_bid = order_book.bids.first.price
        
        ((best_ask - best_bid) / best_ask * 100).round(4)
      end

      def analyze_order_book_depth(order_book)
        {
          ask_levels: order_book.asks.length,
          bid_levels: order_book.bids.length,
          ask_volume: order_book.asks.sum(&:amount),
          bid_volume: order_book.bids.sum(&:amount)
        }
      end

      def calculate_market_metrics(market_analysis)
        markets_with_data = market_analysis.select { |_, data| !data.key?(:error) }
        
        return empty_market_metrics if markets_with_data.empty?
        
        total_volume = markets_with_data.sum { |_, data| data[:volume] }
        avg_change = markets_with_data.sum { |_, data| data[:change_24h] } / markets_with_data.length
        
        # Find best and worst performers
        sorted_by_change = markets_with_data.sort_by { |_, data| data[:change_24h] }
        best_performer = sorted_by_change.last
        worst_performer = sorted_by_change.first
        
        {
          total_volume: total_volume,
          average_change_24h: avg_change,
          markets_analyzed: markets_with_data.length,
          best_performer: {
            market: best_performer[0],
            change: best_performer[1][:change_24h]
          },
          worst_performer: {
            market: worst_performer[0],
            change: worst_performer[1][:change_24h]
          }
        }
      end

      def generate_market_summary(market_analysis, metrics)
        markets_up = market_analysis.count { |_, data| !data.key?(:error) && data[:change_24h] > 0 }
        markets_down = market_analysis.count { |_, data| !data.key?(:error) && data[:change_24h] < 0 }
        
        {
          markets_up: markets_up,
          markets_down: markets_down,
          markets_flat: market_analysis.length - markets_up - markets_down,
          market_sentiment: determine_market_sentiment(metrics[:average_change_24h])
        }
      end

      def determine_market_sentiment(avg_change)
        case avg_change
        when 5.. then "Very Bullish"
        when 2..5 then "Bullish"
        when -2..2 then "Neutral"
        when -5..-2 then "Bearish"
        else "Very Bearish"
        end
      end

      def format_report(report_data, format)
        case format
        when "json"
          JSON.pretty_generate(report_data)
        when "csv"
          format_csv_report(report_data)
        when "html"
          format_html_report(report_data)
        when "markdown"
          format_markdown_report(report_data)
        else
          format_text_report(report_data)
        end
      end

      def format_markdown_report(report_data)
        case report_data[:type]
        when :portfolio_summary
          format_portfolio_markdown(report_data)
        when :trading_performance
          format_trading_markdown(report_data)
        when :market_analysis
          format_market_markdown(report_data)
        when :custom_report
          format_custom_markdown(report_data)
        else
          "# Report\n\n" + JSON.pretty_generate(report_data)
        end
      end

      def format_portfolio_markdown(data)
        """
# Portfolio Summary Report
*Generated: #{data[:generated_at]}*

## Overview
- **Total Portfolio Value:** #{data[:metrics][:total_value_clp].round(2)} CLP
- **Number of Assets:** #{data[:summary][:asset_count]}
- **24h Change:** #{data[:metrics][:total_change_24h_percent].round(2)}% (#{data[:metrics][:total_change_24h].round(2)} CLP)

## Top Holdings
#{format_asset_allocation_markdown(data[:metrics][:asset_allocation])}

## Market Performance
#{format_market_performance_markdown(data[:market_data])}

#{data[:ai_analysis] ? "## AI Analysis\n#{data[:ai_analysis][:content]}" : ""}
        """
      end

      def format_asset_allocation_markdown(allocation)
        lines = ["| Asset | Amount | Value (CLP) | Allocation |"]
        lines << "|-------|---------|-------------|------------|"]
        
        allocation.each do |currency, data|
          lines << "| #{currency} | #{data[:amount].round(8)} | #{data[:value_clp].round(2)} | #{data[:percentage].round(1)}% |"
        end
        
        lines.join("\n")
      end

      def format_market_performance_markdown(market_data)
        return "No market data available" if market_data.empty?
        
        lines = ["| Market | Price | 24h Change | Volume |"]
        lines << "|--------|-------|------------|--------|"]
        
        market_data.each do |currency, data|
          change_symbol = data[:change_24h] >= 0 ? "+" : ""
          lines << "| #{data[:market_id]} | #{data[:price]} | #{change_symbol}#{data[:change_24h].round(2)}% | #{data[:volume].round(2)} |"
        end
        
        lines.join("\n")
      end

      def empty_portfolio_report(format)
        {
          type: :empty_portfolio,
          message: "No portfolio holdings found",
          timestamp: Time.now
        }
      end

      def empty_trading_report(format)
        {
          type: :empty_trading,
          message: "No trading history found",
          timestamp: Time.now
        }
      end

      def empty_performance_metrics
        {
          total_trades: 0,
          buy_trades: 0,
          sell_trades: 0,
          total_volume: 0.0,
          total_fees: 0.0,
          avg_trade_size: 0.0,
          win_rate: 0.0,
          trading_frequency: 0.0,
          most_traded_market: "N/A"
        }
      end

      def empty_market_metrics
        {
          total_volume: 0.0,
          average_change_24h: 0.0,
          markets_analyzed: 0,
          best_performer: { market: "N/A", change: 0.0 },
          worst_performer: { market: "N/A", change: 0.0 }
        }
      end

      # AI integration methods
      def generate_ai_portfolio_analysis(report_data)
        return nil unless defined?(RubyLLM)
        
        prompt = build_portfolio_analysis_prompt(report_data)
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: prompt }],
            max_tokens: 400
          )
          
          {
            content: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI portfolio analysis failed: #{e.message}")
          nil
        end
      end

      def build_portfolio_analysis_prompt(report_data)
        """
        Analyze this cryptocurrency portfolio and provide insights:
        
        Portfolio Value: #{report_data[:metrics][:total_value_clp].round(2)} CLP
        24h Change: #{report_data[:metrics][:total_change_24h_percent].round(2)}%
        Assets: #{report_data[:summary][:asset_count]}
        Top Holding: #{report_data[:metrics][:top_holding][:currency]} (#{report_data[:metrics][:top_holding][:percentage].round(1)}%)
        
        Asset Allocation:
        #{report_data[:metrics][:asset_allocation].map { |currency, data| "- #{currency}: #{data[:percentage].round(1)}%" }.join("\n")}
        
        Provide a brief analysis covering:
        1. Portfolio diversification assessment
        2. Risk factors and opportunities
        3. Specific recommendations for Chilean crypto investors
        
        Keep it concise and actionable.
        """
      end

      def generate_filename(report)
        type = report[:type].to_s.gsub('_', '-')
        timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
        extension = get_file_extension(report[:format])
        
        "buda-#{type}-#{timestamp}.#{extension}"
      end

      def get_file_extension(format)
        case format
        when "json" then "json"
        when "csv" then "csv"
        when "html" then "html"
        when "markdown" then "md"
        else "txt"
        end
      end

      def write_text_report(report, filename)
        File.write(filename, report[:formatted_content])
      end

      def write_json_report(report, filename)
        File.write(filename, JSON.pretty_generate(report[:data]))
      end

      def write_csv_report(report, filename)
        # Basic CSV export - would need enhancement for complex reports
        content = "Type,Generated At,Summary\n"
        content += "#{report[:type]},#{report[:data][:generated_at]},#{report[:data].inspect}"
        
        File.write(filename, content)
      end

      def write_html_report(report, filename)
        html = """
<!DOCTYPE html>
<html>
<head>
    <title>Buda API Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .positive { color: green; }
        .negative { color: red; }
    </style>
</head>
<body>
    <h1>Buda API Report</h1>
    <pre>#{report[:formatted_content]}</pre>
</body>
</html>
        """
        
        File.write(filename, html)
      end

      # Additional helper methods for other report types...
      def fetch_recent_trades_all_markets
        # Implementation for fetching recent trades across all markets
        []
      end

      def fetch_market_overview
        # Implementation for fetching general market overview
        {}
      end

      def generate_ai_custom_report(prompt, data)
        return nil unless defined?(RubyLLM)
        
        data_summary = summarize_data_for_ai(data)
        full_prompt = "#{prompt}\n\nAvailable data:\n#{data_summary}"
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: full_prompt }],
            max_tokens: 800
          )
          
          {
            content: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI custom report failed: #{e.message}")
          { content: "AI analysis unavailable", generated_at: Time.now }
        end
      end

      def summarize_data_for_ai(data)
        summary = []
        
        if data[:portfolio]
          summary << "Portfolio: #{data[:portfolio].length} assets"
        end
        
        if data[:trades]
          summary << "Trades: #{data[:trades].length} recent trades"
        end
        
        if data[:market]
          summary << "Market: Current market overview available"
        end
        
        summary.join(", ")
      end

      # Placeholder methods for additional report formatting
      def format_trading_markdown(data)
        "# Trading Performance Report\n\n*Generated: #{data[:generated_at]}*\n\n" +
        JSON.pretty_generate(data[:performance])
      end

      def format_market_markdown(data)
        "# Market Analysis Report\n\n*Generated: #{data[:generated_at]}*\n\n" +
        JSON.pretty_generate(data[:summary])
      end

      def format_custom_markdown(data)
        content = "# Custom Report\n\n*Generated: #{data[:generated_at]}*\n\n"
        content += "**Request:** #{data[:prompt]}\n\n"
        content += data[:ai_analysis] ? data[:ai_analysis][:content] : "No analysis available"
        content
      end

      def format_text_report(data)
        "Buda API Report\nGenerated: #{data[:generated_at]}\n\n#{JSON.pretty_generate(data)}"
      end

      def format_csv_report(data)
        "Type,Timestamp,Data\n#{data[:type]},#{data[:generated_at]},#{data.inspect}"
      end

      def format_html_report(data)
        "<html><body><h1>Buda API Report</h1><pre>#{JSON.pretty_generate(data)}</pre></body></html>"
      end

      def get_date_range(trades)
        return { start: nil, end: nil } if trades.empty?
        
        dates = trades.map { |t| Time.parse(t[:created_at]) }
        {
          start: dates.min,
          end: dates.max
        }
      end

      def generate_ai_trading_insights(report_data)
        return nil unless defined?(RubyLLM)
        
        prompt = build_trading_insights_prompt(report_data)
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: prompt }],
            max_tokens: 300
          )
          
          {
            content: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI trading insights failed: #{e.message}")
          nil
        end
      end

      def build_trading_insights_prompt(report_data)
        """
        Analyze this trading performance data:
        
        Total Trades: #{report_data[:performance][:total_trades]}
        Win Rate: #{report_data[:performance][:win_rate].round(1)}%
        Total Volume: #{report_data[:performance][:total_volume].round(2)} CLP
        Total Fees: #{report_data[:performance][:total_fees].round(2)} CLP
        Most Traded: #{report_data[:performance][:most_traded_market]}
        
        Provide brief insights on:
        1. Trading performance strengths/weaknesses
        2. Fee optimization opportunities
        3. Strategy improvement recommendations
        """
      end

      def generate_ai_market_insights(report_data)
        return nil unless defined?(RubyLLM)
        
        prompt = build_market_insights_prompt(report_data)
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: prompt }],
            max_tokens: 300
          )
          
          {
            content: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI market insights failed: #{e.message}")
          nil
        end
      end

      def build_market_insights_prompt(report_data)
        """
        Analyze this market data:
        
        Markets Analyzed: #{report_data[:markets_analyzed]}
        Average Change: #{report_data[:metrics][:average_change_24h].round(2)}%
        Best Performer: #{report_data[:metrics][:best_performer][:market]} (+#{report_data[:metrics][:best_performer][:change].round(2)}%)
        Worst Performer: #{report_data[:metrics][:worst_performer][:market]} (#{report_data[:metrics][:worst_performer][:change].round(2)}%)
        Market Sentiment: #{report_data[:summary][:market_sentiment]}
        
        Provide brief market analysis covering:
        1. Current market trends
        2. Trading opportunities
        3. Risk factors to consider
        """
      end
    end
  end
end