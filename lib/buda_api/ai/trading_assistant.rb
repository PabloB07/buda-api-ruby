# frozen_string_literal: true

module BudaApi
  module AI
    # AI-powered trading assistant that provides market analysis and trading insights
    class TradingAssistant
      def initialize(client, llm_provider: :openai, model: nil)
        @client = client
        @llm = RubyLLM.new(
          provider: llm_provider,
          model: model || default_model_for_provider(llm_provider)
        )
        
        BudaApi::Logger.info("Trading Assistant initialized with #{llm_provider}")
      end

      # Analyze market conditions and provide trading insights
      #
      # @param market_id [String] market identifier (e.g., "BTC-CLP")
      # @return [Hash] analysis results with sentiment, signals, and recommendations
      # @example
      #   assistant = BudaApi.trading_assistant(client)
      #   analysis = assistant.analyze_market("BTC-CLP")
      #   puts analysis[:sentiment] # => "bullish", "bearish", or "neutral"
      def analyze_market(market_id)
        BudaApi::Logger.info("Analyzing market #{market_id}")
        
        # Gather comprehensive market data
        ticker = @client.ticker(market_id)
        order_book = @client.order_book(market_id)
        trades = @client.trades(market_id, limit: 50)
        
        # Get historical data for context
        start_time = Time.now - 86400  # 24 hours
        candlesticks = @client.candlestick_report(market_id, start_at: start_time)
        
        prompt = build_market_analysis_prompt(market_id, ticker, order_book, trades, candlesticks)
        
        begin
          analysis = @llm.complete(prompt, max_tokens: 1000)
          parsed_analysis = parse_market_analysis(analysis)
          
          BudaApi::Logger.info("Market analysis completed for #{market_id}")
          parsed_analysis
          
        rescue => e
          BudaApi::Logger.error("Failed to analyze market: #{e.message}")
          {
            error: "Analysis failed: #{e.message}",
            market_id: market_id,
            timestamp: Time.now
          }
        end
      end

      # Suggest trading strategy based on market conditions and user preferences
      #
      # @param market_id [String] market identifier
      # @param balance [Models::Balance] current balance information
      # @param risk_tolerance [String] risk level ("low", "medium", "high")
      # @param investment_horizon [String] time horizon ("short", "medium", "long")
      # @return [Hash] strategy recommendations
      def suggest_trading_strategy(market_id, balance, risk_tolerance: 'medium', investment_horizon: 'medium')
        BudaApi::Logger.info("Generating trading strategy for #{market_id}")
        
        # Get market analysis first
        market_analysis = analyze_market(market_id)
        
        # Get portfolio context
        portfolio_data = gather_portfolio_data(balance)
        
        prompt = build_strategy_prompt(
          market_id, market_analysis, portfolio_data, 
          risk_tolerance, investment_horizon
        )
        
        begin
          strategy = @llm.complete(prompt, max_tokens: 1200)
          parsed_strategy = parse_strategy_recommendations(strategy)
          
          BudaApi::Logger.info("Trading strategy generated for #{market_id}")
          parsed_strategy
          
        rescue => e
          BudaApi::Logger.error("Failed to generate strategy: #{e.message}")
          {
            error: "Strategy generation failed: #{e.message}",
            market_id: market_id,
            timestamp: Time.now
          }
        end
      end

      # Get AI-powered insights on optimal entry/exit points
      #
      # @param market_id [String] market identifier
      # @param action [String] intended action ("buy" or "sell")
      # @param amount [Float] intended trade amount
      # @return [Hash] entry/exit recommendations
      def get_entry_exit_signals(market_id, action, amount)
        BudaApi::Logger.info("Getting #{action} signals for #{amount} #{market_id}")
        
        # Get current market state
        ticker = @client.ticker(market_id)
        order_book = @client.order_book(market_id)
        
        # Get quotation for the intended trade
        quotation_type = action == "buy" ? "bid_given_size" : "ask_given_size"
        quotation = @client.quotation(market_id, quotation_type, amount)
        
        prompt = build_entry_exit_prompt(market_id, action, amount, ticker, order_book, quotation)
        
        begin
          signals = @llm.complete(prompt, max_tokens: 800)
          parsed_signals = parse_entry_exit_signals(signals)
          
          BudaApi::Logger.info("Entry/exit signals generated for #{market_id}")
          parsed_signals
          
        rescue => e
          BudaApi::Logger.error("Failed to generate signals: #{e.message}")
          {
            error: "Signal generation failed: #{e.message}",
            market_id: market_id,
            action: action,
            timestamp: Time.now
          }
        end
      end

      private

      def default_model_for_provider(provider)
        case provider
        when :openai then "gpt-4"
        when :anthropic then "claude-3-sonnet-20240229"
        when :google then "gemini-pro"
        else nil
        end
      end

      def build_market_analysis_prompt(market_id, ticker, order_book, trades, candlesticks)
        recent_trades_summary = summarize_recent_trades(trades)
        price_action = analyze_price_action(candlesticks) if candlesticks.any?
        
        """
        Analyze the following cryptocurrency market data for #{market_id} and provide comprehensive insights:

        CURRENT MARKET STATE:
        - Current Price: #{ticker.last_price}
        - 24h Change: #{ticker.price_variation_24h}%
        - 7d Change: #{ticker.price_variation_7d}%
        - Volume: #{ticker.volume}
        - Min Ask: #{ticker.min_ask}
        - Max Bid: #{ticker.max_bid}

        ORDER BOOK:
        - Best Ask: #{order_book.best_ask.price} (#{order_book.best_ask.amount})
        - Best Bid: #{order_book.best_bid.price} (#{order_book.best_bid.amount})
        - Spread: #{order_book.spread_percentage}%
        - Order Book Depth: #{order_book.asks.length} asks, #{order_book.bids.length} bids

        RECENT TRADING ACTIVITY:
        #{recent_trades_summary}

        #{price_action ? "PRICE ACTION (24H):\n#{price_action}" : ""}

        Please provide a comprehensive analysis including:
        1. Overall market sentiment (bullish/bearish/neutral)
        2. Key support and resistance levels
        3. Market momentum indicators
        4. Volume analysis
        5. Short-term price prediction (next 1-4 hours)
        6. Risk factors to consider
        7. Trading opportunities
        8. Confidence level (1-10) for your analysis

        Format your response as structured analysis with clear sections.
        """
      end

      def build_strategy_prompt(market_id, market_analysis, portfolio_data, risk_tolerance, investment_horizon)
        """
        Based on the following information, suggest a comprehensive trading strategy:

        MARKET: #{market_id}
        MARKET ANALYSIS:
        #{format_analysis_for_prompt(market_analysis)}

        PORTFOLIO CONTEXT:
        #{format_portfolio_for_prompt(portfolio_data)}

        USER PREFERENCES:
        - Risk Tolerance: #{risk_tolerance}
        - Investment Horizon: #{investment_horizon}

        Please provide:
        1. Recommended strategy type (DCA, swing trade, scalping, etc.)
        2. Position sizing recommendations
        3. Entry price targets
        4. Exit strategies (profit targets and stop losses)
        5. Risk management rules
        6. Timeline for the strategy
        7. Specific action steps
        8. Alternative scenarios to consider

        Tailor recommendations to the user's risk tolerance and investment horizon.
        """
      end

      def build_entry_exit_prompt(market_id, action, amount, ticker, order_book, quotation)
        """
        Provide optimal entry/exit timing for the following trade:

        INTENDED TRADE:
        - Market: #{market_id}
        - Action: #{action.upcase}
        - Amount: #{amount}
        - Estimated Cost: #{quotation.quote_balance_change}
        - Fee: #{quotation.fee}

        CURRENT MARKET CONDITIONS:
        - Current Price: #{ticker.last_price}
        - Best Ask: #{order_book.best_ask.price}
        - Best Bid: #{order_book.best_bid.price}
        - Spread: #{order_book.spread_percentage}%

        Please recommend:
        1. Optimal timing for entry (immediate, wait for dip, etc.)
        2. Suggested order type (market vs limit)
        3. If limit order, suggested price levels
        4. Risk factors for this specific trade
        5. Alternative amounts to consider
        6. Market conditions to monitor before executing

        Be specific with price levels and timing recommendations.
        """
      end

      def summarize_recent_trades(trades)
        return "No recent trades available" if trades.count == 0
        
        total_volume = trades.trades.sum { |t| t.amount.amount }
        buy_volume = trades.trades.select { |t| t.direction == "up" }.sum { |t| t.amount.amount }
        sell_volume = total_volume - buy_volume
        
        "#{trades.count} recent trades, #{total_volume.round(4)} total volume (#{(buy_volume/total_volume*100).round(1)}% buys)"
      end

      def analyze_price_action(candlesticks)
        return nil if candlesticks.length < 2
        
        first_candle = candlesticks.first
        last_candle = candlesticks.last
        
        price_change = ((last_candle.close - first_candle.open) / first_candle.open * 100).round(2)
        high = candlesticks.max_by(&:high).high
        low = candlesticks.min_by(&:low).low
        
        "Price moved #{price_change}% (High: #{high}, Low: #{low})"
      end

      def gather_portfolio_data(balance)
        {
          currency: balance.currency,
          total_amount: balance.amount,
          available: balance.available_amount,
          frozen: balance.frozen_amount,
          pending_withdrawals: balance.pending_withdraw_amount
        }
      end

      def parse_market_analysis(analysis_text)
        # Extract structured data from AI response
        sentiment = extract_sentiment(analysis_text)
        confidence = extract_confidence(analysis_text)
        
        {
          raw_analysis: analysis_text,
          sentiment: sentiment,
          confidence: confidence,
          timestamp: Time.now,
          summary: extract_summary(analysis_text)
        }
      end

      def parse_strategy_recommendations(strategy_text)
        {
          raw_strategy: strategy_text,
          strategy_type: extract_strategy_type(strategy_text),
          action_steps: extract_action_steps(strategy_text),
          risk_level: extract_risk_level(strategy_text),
          timestamp: Time.now
        }
      end

      def parse_entry_exit_signals(signals_text)
        {
          raw_signals: signals_text,
          timing_recommendation: extract_timing(signals_text),
          suggested_price: extract_price_target(signals_text),
          risk_factors: extract_risk_factors(signals_text),
          timestamp: Time.now
        }
      end

      # Simple text extraction methods (could be enhanced with more sophisticated parsing)
      def extract_sentiment(text)
        text_lower = text.downcase
        if text_lower.include?('bullish') || text_lower.include?('positive')
          'bullish'
        elsif text_lower.include?('bearish') || text_lower.include?('negative')
          'bearish'
        else
          'neutral'
        end
      end

      def extract_confidence(text)
        # Look for confidence patterns like "confidence: 7/10" or "7 out of 10"
        match = text.match(/confidence[:\s]*(\d+)(?:\/10|\/\d+|\s*out\s*of\s*10)/i)
        match ? match[1].to_i : 5  # Default to 5 if not found
      end

      def extract_summary(text)
        # Extract first few sentences as summary
        sentences = text.split(/[.!?]+/)
        sentences.first(2).join('. ').strip
      end

      def extract_strategy_type(text)
        text_lower = text.downcase
        if text_lower.include?('dca') || text_lower.include?('dollar cost')
          'DCA'
        elsif text_lower.include?('swing')
          'swing_trading'
        elsif text_lower.include?('scalp')
          'scalping'
        elsif text_lower.include?('hold') || text_lower.include?('hodl')
          'hold'
        else
          'mixed'
        end
      end

      def extract_action_steps(text)
        # Look for numbered lists or bullet points
        steps = text.scan(/(?:^\d+\.|\*|\-)\s*(.+)$/m).flatten
        steps.empty? ? ["Review the full strategy analysis"] : steps
      end

      def extract_risk_level(text)
        text_lower = text.downcase
        if text_lower.include?('high risk') || text_lower.include?('very risky')
          'high'
        elsif text_lower.include?('low risk') || text_lower.include?('conservative')
          'low'
        else
          'medium'
        end
      end

      def extract_timing(text)
        text_lower = text.downcase
        if text_lower.include?('immediate') || text_lower.include?('now')
          'immediate'
        elsif text_lower.include?('wait') || text_lower.include?('delay')
          'wait'
        elsif text_lower.include?('monitor') || text_lower.include?('watch')
          'monitor'
        else
          'evaluate'
        end
      end

      def extract_price_target(text)
        # Look for price patterns (simple regex for CLP prices)
        match = text.match(/(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*CLP/i)
        match ? match[1].gsub(',', '').to_f : nil
      end

      def extract_risk_factors(text)
        # Look for risk-related bullet points or sentences
        risks = text.scan(/(?:risk|danger|warning|caution)[:\s]*([^.!?]+)/i).flatten
        risks.empty? ? ["Market volatility"] : risks.map(&:strip)
      end

      def format_analysis_for_prompt(analysis)
        return "Analysis not available" unless analysis.is_a?(Hash)
        
        "Sentiment: #{analysis[:sentiment] || 'unknown'}\n" +
        "Confidence: #{analysis[:confidence] || 'unknown'}\n" +
        "Summary: #{analysis[:summary] || analysis[:raw_analysis]&.slice(0, 200)}"
      end

      def format_portfolio_for_prompt(portfolio)
        "Currency: #{portfolio[:currency]}\n" +
        "Available: #{portfolio[:available]}\n" +
        "Total: #{portfolio[:total_amount]}\n" +
        "Frozen: #{portfolio[:frozen]}"
      end
    end
  end
end