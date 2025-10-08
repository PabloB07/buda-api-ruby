# frozen_string_literal: true

module BudaApi
  # Public API client for endpoints that don't require authentication
  class PublicClient < Client
    include Models

    # Get all available markets
    #
    # @return [Array<Market>] list of available markets
    # @example
    #   client = BudaApi::PublicClient.new
    #   markets = client.markets
    #   markets.each { |market| puts "#{market.id}: #{market.name}" }
    def markets
      BudaApi::Logger.info("Fetching all markets")
      
      response = get("markets")
      markets_data = response["markets"] || []
      
      markets = markets_data.map { |market_data| Market.new(market_data) }
      BudaApi::Logger.info("Retrieved #{markets.length} markets")
      
      markets
    end

    # Get details for a specific market
    #
    # @param market_id [String] market identifier (e.g., "BTC-CLP")
    # @return [Market] market details
    # @example
    #   client = BudaApi::PublicClient.new
    #   market = client.market_details("BTC-CLP")
    #   puts "Minimum order: #{market.minimum_order_amount}"
    def market_details(market_id)
      validate_required_params({ market_id: market_id }, [:market_id])
      validate_param_values({ market_id: market_id }, { market_id: Market::ALL })

      BudaApi::Logger.info("Fetching market details for #{market_id}")
      
      response = get("markets/#{market_id}")
      Market.new(response["market"])
    end

    # Get ticker information for a market
    #
    # @param market_id [String] market identifier
    # @return [Ticker] current ticker information
    # @example
    #   client = BudaApi::PublicClient.new  
    #   ticker = client.ticker("BTC-CLP")
    #   puts "Last price: #{ticker.last_price}"
    #   puts "24h change: #{ticker.price_variation_24h}%"
    def ticker(market_id)
      validate_required_params({ market_id: market_id }, [:market_id])
      validate_param_values({ market_id: market_id }, { market_id: Market::ALL })

      BudaApi::Logger.info("Fetching ticker for #{market_id}")
      
      response = get("markets/#{market_id}/ticker")
      Ticker.new(response["ticker"])
    end

    # Get order book for a market
    #
    # @param market_id [String] market identifier
    # @return [OrderBook] current order book
    # @example
    #   client = BudaApi::PublicClient.new
    #   order_book = client.order_book("BTC-CLP") 
    #   puts "Best ask: #{order_book.best_ask.price}"
    #   puts "Best bid: #{order_book.best_bid.price}"
    #   puts "Spread: #{order_book.spread_percentage}%"
    def order_book(market_id)
      validate_required_params({ market_id: market_id }, [:market_id])
      validate_param_values({ market_id: market_id }, { market_id: Market::ALL })

      BudaApi::Logger.info("Fetching order book for #{market_id}")
      
      response = get("markets/#{market_id}/order_book")
      OrderBook.new(response["order_book"])
    end

    # Get recent trades for a market
    #
    # @param market_id [String] market identifier  
    # @param timestamp [Integer, nil] trades after this timestamp
    # @param limit [Integer, nil] maximum number of trades to return
    # @return [Trades] collection of recent trades
    # @example
    #   client = BudaApi::PublicClient.new
    #   trades = client.trades("BTC-CLP", limit: 10)
    #   trades.each { |trade| puts "#{trade.amount} at #{trade.price}" }
    def trades(market_id, timestamp: nil, limit: nil)
      validate_required_params({ market_id: market_id }, [:market_id])
      validate_param_values({ market_id: market_id }, { market_id: Market::ALL })

      params = normalize_params({
        timestamp: timestamp,
        limit: limit
      })

      BudaApi::Logger.info("Fetching trades for #{market_id} with params: #{params}")
      
      response = get("markets/#{market_id}/trades", params)
      Trades.new(response["trades"])
    end

    # Get a quotation for a potential trade
    #
    # @param market_id [String] market identifier
    # @param quotation_type [String] type of quotation
    # @param amount [Float] amount for quotation
    # @param limit [Float, nil] limit price for limit quotations
    # @return [Quotation] quotation details
    # @example
    #   client = BudaApi::PublicClient.new
    #   # Get quotation for buying 0.1 BTC at market price
    #   quote = client.quotation("BTC-CLP", "bid_given_size", 0.1)
    #   puts "You would pay: #{quote.quote_balance_change}"
    def quotation(market_id, quotation_type, amount, limit: nil)
      validate_required_params({ 
        market_id: market_id, 
        quotation_type: quotation_type, 
        amount: amount 
      }, [:market_id, :quotation_type, :amount])
      
      validate_param_values({ 
        market_id: market_id,
        quotation_type: quotation_type 
      }, { 
        market_id: Market::ALL,
        quotation_type: QuotationType::ALL 
      })

      quotation_payload = {
        type: quotation_type,
        amount: amount.to_s
      }
      quotation_payload[:limit] = limit.to_s if limit

      BudaApi::Logger.info("Getting quotation for #{market_id}: #{quotation_type} #{amount}")
      
      response = post("markets/#{market_id}/quotations", body: { quotation: quotation_payload })
      Quotation.new(response["quotation"])
    end

    # Get a market quotation (no limit price)
    #
    # @param market_id [String] market identifier
    # @param quotation_type [String] type of quotation
    # @param amount [Float] amount for quotation 
    # @return [Quotation] market quotation details
    def quotation_market(market_id, quotation_type, amount)
      quotation(market_id, quotation_type, amount)
    end

    # Get a limit quotation (with limit price)
    #
    # @param market_id [String] market identifier
    # @param quotation_type [String] type of quotation
    # @param amount [Float] amount for quotation
    # @param limit [Float] limit price
    # @return [Quotation] limit quotation details
    def quotation_limit(market_id, quotation_type, amount, limit)
      quotation(market_id, quotation_type, amount, limit: limit)
    end

    # Get average prices report
    #
    # @param market_id [String] market identifier
    # @param start_at [Time, nil] start time for report
    # @param end_at [Time, nil] end time for report  
    # @return [Array<AveragePrice>] average price data points
    # @example
    #   client = BudaApi::PublicClient.new
    #   start_time = Time.now - 86400  # 24 hours ago
    #   prices = client.average_prices_report("BTC-CLP", start_at: start_time)
    def average_prices_report(market_id, start_at: nil, end_at: nil)
      get_report(market_id, ReportType::AVERAGE_PRICES, start_at, end_at) do |report_data|
        AveragePrice.new(report_data)
      end
    end

    # Get candlestick report
    #
    # @param market_id [String] market identifier
    # @param start_at [Time, nil] start time for report
    # @param end_at [Time, nil] end time for report
    # @return [Array<Candlestick>] candlestick data points
    # @example
    #   client = BudaApi::PublicClient.new
    #   start_time = Time.now - 86400  # 24 hours ago
    #   candles = client.candlestick_report("BTC-CLP", start_at: start_time)
    def candlestick_report(market_id, start_at: nil, end_at: nil)
      get_report(market_id, ReportType::CANDLESTICK, start_at, end_at) do |report_data|
        Candlestick.new(report_data)
      end
    end

    private

    def get_report(market_id, report_type, start_at, end_at)
      validate_required_params({ 
        market_id: market_id,
        report_type: report_type 
      }, [:market_id, :report_type])
      
      validate_param_values({ 
        market_id: market_id,
        report_type: report_type 
      }, { 
        market_id: Market::ALL,
        report_type: ReportType::ALL 
      })

      params = normalize_params({
        report_type: report_type,
        from: start_at&.to_i,
        to: end_at&.to_i
      })

      BudaApi::Logger.info("Fetching #{report_type} report for #{market_id}")
      
      response = get("markets/#{market_id}/reports", params)
      reports_data = response["reports"] || []
      
      reports_data.map { |report_data| yield(report_data) }
    end
  end
end