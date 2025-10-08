# frozen_string_literal: true

module BudaApi
  module AI
    # AI-powered risk management and portfolio analysis
    class RiskManager
      RISK_LEVELS = {
        very_low: { score: 1, color: "🟢", description: "Very low risk" },
        low: { score: 2, color: "🟡", description: "Low risk" },
        medium: { score: 3, color: "🟠", description: "Medium risk" },
        high: { score: 4, color: "🔴", description: "High risk" },
        very_high: { score: 5, color: "🚫", description: "Very high risk - avoid!" }
      }.freeze

      PORTFOLIO_RISK_FACTORS = [
        "concentration_risk",
        "volatility_risk", 
        "liquidity_risk",
        "correlation_risk",
        "size_risk"
      ].freeze

      def initialize(client, llm_provider: :openai)
        @client = client
        @llm = RubyLLM.new(
          provider: llm_provider,
          system_prompt: build_risk_system_prompt
        )
        
        BudaApi::Logger.info("Risk Manager initialized")
      end

      # Analyze portfolio risk across all holdings
      #
      # @param options [Hash] analysis options
      # @option options [Boolean] :include_ai_insights include AI analysis
      # @option options [Array<String>] :focus_factors specific risk factors to analyze
      # @return [Hash] comprehensive risk analysis
      def analyze_portfolio_risk(options = {})
        BudaApi::Logger.info("Analyzing portfolio risk")
        
        begin
          # Get account balances
          balances_result = @client.balances
          portfolios = extract_non_zero_balances(balances_result)
          
          return no_portfolio_risk if portfolios.empty?
          
          # Calculate basic risk metrics
          basic_metrics = calculate_basic_risk_metrics(portfolios)
          
          # Get market data for risk calculations
          market_data = fetch_market_data_for_portfolio(portfolios)
          
          # Calculate advanced risk metrics
          advanced_metrics = calculate_advanced_risk_metrics(portfolios, market_data)
          
          # Generate overall risk assessment
          overall_risk = calculate_overall_risk_score(basic_metrics, advanced_metrics)
          
          result = {
            type: :portfolio_risk_analysis,
            timestamp: Time.now,
            portfolio_value: basic_metrics[:total_value],
            currency_count: portfolios.length,
            overall_risk: overall_risk,
            basic_metrics: basic_metrics,
            advanced_metrics: advanced_metrics,
            recommendations: generate_risk_recommendations(overall_risk, basic_metrics, advanced_metrics),
            holdings: portfolios
          }
          
          # Add AI insights if requested
          if options[:include_ai_insights]
            result[:ai_insights] = generate_ai_risk_insights(result)
          end
          
          result
          
        rescue => e
          error_msg = "Portfolio risk analysis failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :risk_analysis_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Evaluate risk for a specific trade before execution
      #
      # @param market_id [String] trading pair
      # @param side [String] 'buy' or 'sell'
      # @param amount [Float] trade amount
      # @param price [Float] trade price (optional)
      # @return [Hash] trade risk assessment
      def evaluate_trade_risk(market_id, side, amount, price = nil)
        BudaApi::Logger.info("Evaluating trade risk for #{side} #{amount} #{market_id}")
        
        begin
          # Get current market data
          ticker = @client.ticker(market_id)
          order_book = @client.order_book(market_id)
          
          # Get current portfolio
          balances_result = @client.balances
          current_portfolio = extract_non_zero_balances(balances_result)
          
          # Calculate trade impact
          trade_impact = calculate_trade_impact(market_id, side, amount, price, ticker, order_book)
          
          # Calculate position sizing risk
          position_risk = calculate_position_risk(market_id, amount, ticker.last_price.amount, current_portfolio)
          
          # Calculate market impact risk
          market_impact_risk = calculate_market_impact_risk(amount, price || ticker.last_price.amount, order_book)
          
          # Generate overall trade risk score
          trade_risk_score = calculate_trade_risk_score(trade_impact, position_risk, market_impact_risk)
          
          {
            type: :trade_risk_evaluation,
            market_id: market_id,
            side: side,
            amount: amount,
            price: price,
            risk_level: determine_risk_level(trade_risk_score),
            risk_score: trade_risk_score,
            trade_impact: trade_impact,
            position_risk: position_risk,
            market_impact_risk: market_impact_risk,
            recommendations: generate_trade_recommendations(trade_risk_score, trade_impact),
            should_proceed: trade_risk_score < 3.5,
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Trade risk evaluation failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :trade_risk_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Monitor portfolio for risk threshold breaches
      #
      # @param thresholds [Hash] risk thresholds to monitor
      # @return [Hash] monitoring results with alerts
      def monitor_risk_thresholds(thresholds = {})
        default_thresholds = {
          max_position_percentage: 30.0,
          max_daily_loss: 5.0,
          min_diversification_score: 0.6,
          max_volatility_score: 4.0
        }
        
        thresholds = default_thresholds.merge(thresholds)
        
        BudaApi::Logger.info("Monitoring risk thresholds")
        
        begin
          # Get current portfolio analysis
          portfolio_analysis = analyze_portfolio_risk
          
          alerts = []
          
          # Check position concentration
          if portfolio_analysis[:basic_metrics][:max_position_percentage] > thresholds[:max_position_percentage]
            alerts << {
              type: :concentration_alert,
              level: :high,
              message: "🚨 Position concentration too high: #{portfolio_analysis[:basic_metrics][:max_position_percentage].round(1)}% (limit: #{thresholds[:max_position_percentage]}%)",
              current_value: portfolio_analysis[:basic_metrics][:max_position_percentage],
              threshold: thresholds[:max_position_percentage]
            }
          end
          
          # Check diversification
          if portfolio_analysis[:advanced_metrics][:diversification_score] < thresholds[:min_diversification_score]
            alerts << {
              type: :diversification_alert,
              level: :medium,
              message: "⚠️ Portfolio not well diversified: #{portfolio_analysis[:advanced_metrics][:diversification_score].round(2)} (minimum: #{thresholds[:min_diversification_score]})",
              current_value: portfolio_analysis[:advanced_metrics][:diversification_score],
              threshold: thresholds[:min_diversification_score]
            }
          end
          
          # Check overall volatility
          if portfolio_analysis[:overall_risk][:score] > thresholds[:max_volatility_score]
            alerts << {
              type: :volatility_alert,
              level: :high,
              message: "🔥 Portfolio volatility too high: #{portfolio_analysis[:overall_risk][:score].round(1)} (limit: #{thresholds[:max_volatility_score]})",
              current_value: portfolio_analysis[:overall_risk][:score],
              threshold: thresholds[:max_volatility_score]
            }
          end
          
          {
            type: :risk_monitoring,
            timestamp: Time.now,
            alerts_count: alerts.length,
            alerts: alerts,
            thresholds: thresholds,
            portfolio_summary: {
              total_value: portfolio_analysis[:portfolio_value],
              risk_level: portfolio_analysis[:overall_risk][:level],
              risk_score: portfolio_analysis[:overall_risk][:score]
            },
            safe: alerts.empty?
          }
          
        rescue => e
          error_msg = "Risk monitoring failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :risk_monitoring_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Generate stop-loss recommendations based on risk analysis
      #
      # @param market_id [String] trading pair
      # @param position_size [Float] current position size
      # @return [Hash] stop-loss recommendations
      def recommend_stop_loss(market_id, position_size)
        BudaApi::Logger.info("Generating stop-loss recommendations for #{market_id}")
        
        begin
          ticker = @client.ticker(market_id)
          current_price = ticker.last_price.amount
          
          # Calculate different stop-loss levels
          conservative_stop = current_price * 0.95  # 5% stop loss
          moderate_stop = current_price * 0.90      # 10% stop loss
          aggressive_stop = current_price * 0.85    # 15% stop loss
          
          # Calculate potential losses
          position_value = position_size * current_price
          
          {
            type: :stop_loss_recommendations,
            market_id: market_id,
            current_price: current_price,
            position_size: position_size,
            position_value: position_value,
            recommendations: {
              conservative: {
                price: conservative_stop,
                percentage: 5.0,
                max_loss: position_value * 0.05,
                description: "Conservative 5% stop-loss for capital preservation"
              },
              moderate: {
                price: moderate_stop,
                percentage: 10.0,
                max_loss: position_value * 0.10,
                description: "Moderate 10% stop-loss balancing protection and flexibility"
              },
              aggressive: {
                price: aggressive_stop,
                percentage: 15.0,
                max_loss: position_value * 0.15,
                description: "Aggressive 15% stop-loss for volatile markets"
              }
            },
            recommendation: determine_best_stop_loss(ticker, position_value),
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Stop-loss recommendation failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :stop_loss_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      private

      def build_risk_system_prompt
        """
        You are an expert risk management analyst for cryptocurrency trading.
        
        Your expertise includes:
        - Portfolio diversification analysis
        - Position sizing recommendations
        - Volatility assessment
        - Correlation analysis between crypto assets
        - Market risk evaluation
        - Risk-adjusted return optimization
        
        When analyzing risks:
        1. Consider both technical and fundamental factors
        2. Account for crypto market volatility and correlations
        3. Provide specific, actionable recommendations
        4. Explain risk levels in simple terms
        5. Consider Chilean market conditions and regulations
        
        Always prioritize capital preservation while identifying opportunities.
        Be conservative with risk assessments - it's better to be cautious.
        """
      end

      def extract_non_zero_balances(balances_result)
        balances_result.balances.select do |balance|
          balance.amount.amount > 0.0001  # Filter out dust
        end.map do |balance|
          {
            currency: balance.currency,
            amount: balance.amount.amount,
            available: balance.available_amount.amount,
            frozen: balance.frozen_amount.amount
          }
        end
      end

      def no_portfolio_risk
        {
          type: :no_portfolio,
          message: "No significant portfolio holdings to analyze",
          timestamp: Time.now
        }
      end

      def calculate_basic_risk_metrics(portfolios)
        # Calculate total portfolio value in CLP
        total_value_clp = calculate_total_portfolio_value_clp(portfolios)
        
        # Calculate position percentages
        position_percentages = calculate_position_percentages(portfolios, total_value_clp)
        
        # Find largest position
        max_position_percentage = position_percentages.values.max || 0
        
        {
          total_value: total_value_clp,
          currency_count: portfolios.length,
          max_position_percentage: max_position_percentage,
          position_percentages: position_percentages,
          is_concentrated: max_position_percentage > 50.0
        }
      end

      def calculate_total_portfolio_value_clp(portfolios)
        total_value = 0.0
        
        portfolios.each do |holding|
          if holding[:currency] == "CLP"
            total_value += holding[:amount]
          else
            # Get current market price for conversion to CLP
            market_id = "#{holding[:currency]}-CLP"
            begin
              ticker = @client.ticker(market_id)
              total_value += holding[:amount] * ticker.last_price.amount
            rescue
              # Skip if market doesn't exist or API fails
              BudaApi::Logger.warn("Could not get price for #{market_id}")
            end
          end
        end
        
        total_value
      end

      def calculate_position_percentages(portfolios, total_value_clp)
        percentages = {}
        
        portfolios.each do |holding|
          currency = holding[:currency]
          
          if currency == "CLP"
            value_clp = holding[:amount]
          else
            market_id = "#{currency}-CLP"
            begin
              ticker = @client.ticker(market_id)
              value_clp = holding[:amount] * ticker.last_price.amount
            rescue
              value_clp = 0.0
            end
          end
          
          percentage = total_value_clp > 0 ? (value_clp / total_value_clp) * 100 : 0
          percentages[currency] = percentage
        end
        
        percentages
      end

      def fetch_market_data_for_portfolio(portfolios)
        market_data = {}
        
        portfolios.each do |holding|
          currency = holding[:currency]
          next if currency == "CLP"
          
          market_id = "#{currency}-CLP"
          begin
            ticker = @client.ticker(market_id)
            market_data[currency] = {
              price: ticker.last_price.amount,
              volume: ticker.volume.amount,
              change_24h: ticker.price_variation_24h
            }
          rescue => e
            BudaApi::Logger.warn("Could not fetch market data for #{market_id}: #{e.message}")
          end
        end
        
        market_data
      end

      def calculate_advanced_risk_metrics(portfolios, market_data)
        # Calculate diversification score (Simpson's index)
        diversification_score = calculate_diversification_score(portfolios)
        
        # Calculate volatility score based on 24h changes
        volatility_score = calculate_volatility_score(market_data)
        
        # Calculate correlation risk (simplified)
        correlation_risk = calculate_correlation_risk(portfolios)
        
        {
          diversification_score: diversification_score,
          volatility_score: volatility_score,
          correlation_risk: correlation_risk,
          risk_factors: analyze_risk_factors(portfolios, market_data)
        }
      end

      def calculate_diversification_score(portfolios)
        return 0.0 if portfolios.empty?
        
        total_amount = portfolios.sum { |p| p[:amount] }
        return 0.0 if total_amount == 0
        
        # Calculate Simpson's diversity index
        sum_of_squares = portfolios.sum do |holding|
          proportion = holding[:amount] / total_amount
          proportion ** 2
        end
        
        # Convert to 0-1 scale where 1 is perfectly diversified
        1.0 - sum_of_squares
      end

      def calculate_volatility_score(market_data)
        return 1.0 if market_data.empty?
        
        # Calculate average absolute change across holdings
        changes = market_data.values.map { |data| data[:change_24h].abs }
        avg_volatility = changes.sum / changes.length
        
        # Convert to 1-5 scale
        case avg_volatility
        when 0..2 then 1.0
        when 2..5 then 2.0
        when 5..10 then 3.0
        when 10..20 then 4.0
        else 5.0
        end
      end

      def calculate_correlation_risk(portfolios)
        # Simplified correlation analysis
        # In a real implementation, this would use historical price correlations
        
        crypto_count = portfolios.count { |p| p[:currency] != "CLP" }
        
        case crypto_count
        when 0..1 then 1.0  # Low correlation risk with few assets
        when 2..3 then 2.0  # Medium risk
        when 4..6 then 3.0  # Higher risk - many cryptos tend to correlate
        else 4.0           # High correlation risk
        end
      end

      def analyze_risk_factors(portfolios, market_data)
        factors = {}
        
        # Concentration risk
        max_position = portfolios.max_by { |p| p[:amount] }
        factors[:concentration] = max_position ? calculate_concentration_risk(max_position, portfolios) : 1.0
        
        # Liquidity risk
        factors[:liquidity] = calculate_liquidity_risk(market_data)
        
        # Size risk
        factors[:size] = calculate_size_risk(portfolios)
        
        factors
      end

      def calculate_concentration_risk(max_position, portfolios)
        total_value = portfolios.sum { |p| p[:amount] }
        concentration = max_position[:amount] / total_value
        
        case concentration
        when 0..0.3 then 1.0
        when 0.3..0.5 then 2.0
        when 0.5..0.7 then 3.0
        when 0.7..0.9 then 4.0
        else 5.0
        end
      end

      def calculate_liquidity_risk(market_data)
        return 1.0 if market_data.empty?
        
        # Use volume as proxy for liquidity
        volumes = market_data.values.map { |data| data[:volume] }
        avg_volume = volumes.sum / volumes.length
        
        # Rough categorization based on volume
        case avg_volume
        when 1000000.. then 1.0  # High liquidity
        when 100000..1000000 then 2.0
        when 10000..100000 then 3.0
        when 1000..10000 then 4.0
        else 5.0  # Low liquidity
        end
      end

      def calculate_size_risk(portfolios)
        total_currencies = portfolios.length
        
        case total_currencies
        when 5.. then 1.0     # Well diversified
        when 3..4 then 2.0    # Moderately diversified
        when 2 then 3.0       # Limited diversification
        when 1 then 5.0       # No diversification
        else 1.0
        end
      end

      def calculate_overall_risk_score(basic_metrics, advanced_metrics)
        # Weighted average of different risk components
        concentration_weight = 0.3
        volatility_weight = 0.25
        diversification_weight = 0.25
        correlation_weight = 0.2
        
        concentration_risk = basic_metrics[:is_concentrated] ? 4.0 : 2.0
        volatility_risk = advanced_metrics[:volatility_score]
        diversification_risk = (1.0 - advanced_metrics[:diversification_score]) * 5.0
        correlation_risk = advanced_metrics[:correlation_risk]
        
        weighted_score = (
          concentration_risk * concentration_weight +
          volatility_risk * volatility_weight +
          diversification_risk * diversification_weight +
          correlation_risk * correlation_weight
        )
        
        risk_level = determine_risk_level(weighted_score)
        
        {
          score: weighted_score,
          level: risk_level[:description],
          color: risk_level[:color],
          components: {
            concentration: concentration_risk,
            volatility: volatility_risk,
            diversification: diversification_risk,
            correlation: correlation_risk
          }
        }
      end

      def determine_risk_level(score)
        case score
        when 0..1.5 then RISK_LEVELS[:very_low]
        when 1.5..2.5 then RISK_LEVELS[:low]
        when 2.5..3.5 then RISK_LEVELS[:medium]
        when 3.5..4.5 then RISK_LEVELS[:high]
        else RISK_LEVELS[:very_high]
        end
      end

      def generate_risk_recommendations(overall_risk, basic_metrics, advanced_metrics)
        recommendations = []
        
        # Concentration recommendations
        if basic_metrics[:max_position_percentage] > 50
          recommendations << {
            type: :diversification,
            priority: :high,
            message: "🎯 Reduce position concentration - largest holding is #{basic_metrics[:max_position_percentage].round(1)}%"
          }
        end
        
        # Diversification recommendations
        if advanced_metrics[:diversification_score] < 0.6
          recommendations << {
            type: :diversification,
            priority: :medium,
            message: "📊 Improve diversification across more assets"
          }
        end
        
        # Volatility recommendations
        if advanced_metrics[:volatility_score] > 3.5
          recommendations << {
            type: :volatility,
            priority: :high,
            message: "🌊 Consider reducing exposure to high-volatility assets"
          }
        end
        
        recommendations
      end

      def calculate_trade_impact(market_id, side, amount, price, ticker, order_book)
        current_price = ticker.last_price.amount
        trade_price = price || current_price
        
        # Calculate price impact
        price_impact_percent = ((trade_price - current_price) / current_price * 100).abs
        
        # Calculate size impact relative to order book
        relevant_side = side == "buy" ? order_book.asks : order_book.bids
        total_volume = relevant_side.sum(&:amount)
        size_impact_percent = total_volume > 0 ? (amount / total_volume * 100) : 0
        
        {
          price_impact_percent: price_impact_percent,
          size_impact_percent: size_impact_percent,
          estimated_cost: amount * trade_price,
          current_market_price: current_price,
          price_deviation: price_impact_percent
        }
      end

      def calculate_position_risk(market_id, amount, price, current_portfolio)
        trade_value = amount * price
        
        # Get current portfolio value
        total_portfolio_value = calculate_total_portfolio_value_clp(current_portfolio)
        
        position_percentage = total_portfolio_value > 0 ? (trade_value / total_portfolio_value * 100) : 0
        
        {
          trade_value: trade_value,
          portfolio_percentage: position_percentage,
          is_significant: position_percentage > 10.0,
          risk_level: case position_percentage
            when 0..5 then :low
            when 5..15 then :medium
            when 15..30 then :high
            else :very_high
          end
        }
      end

      def calculate_market_impact_risk(amount, price, order_book)
        # Analyze order book depth
        trade_side = order_book.asks.first(10)  # Look at top 10 levels
        cumulative_volume = 0
        levels_needed = 0
        
        trade_side.each do |level|
          cumulative_volume += level.amount
          levels_needed += 1
          break if cumulative_volume >= amount
        end
        
        {
          levels_needed: levels_needed,
          available_volume: cumulative_volume,
          impact_score: case levels_needed
            when 1 then 1.0      # Low impact - fits in top level
            when 2..3 then 2.0   # Medium impact
            when 4..6 then 3.0   # High impact
            else 4.0             # Very high impact
          end
        }
      end

      def calculate_trade_risk_score(trade_impact, position_risk, market_impact_risk)
        # Combine different risk factors
        price_risk = trade_impact[:price_impact_percent] / 5.0  # Normalize to 0-4 scale
        position_risk_score = case position_risk[:risk_level]
          when :low then 1.0
          when :medium then 2.5
          when :high then 4.0
          when :very_high then 5.0
        end
        market_risk_score = market_impact_risk[:impact_score]
        
        # Weighted average
        (price_risk * 0.3 + position_risk_score * 0.4 + market_risk_score * 0.3)
      end

      def generate_trade_recommendations(risk_score, trade_impact)
        recommendations = []
        
        if risk_score > 3.5
          recommendations << "🚨 High risk trade - consider reducing size"
        end
        
        if trade_impact[:size_impact_percent] > 20
          recommendations << "📊 Large market impact - consider splitting into smaller orders"
        end
        
        if trade_impact[:price_deviation] > 5
          recommendations << "💰 Significant price deviation - verify price is intentional"
        end
        
        recommendations << "✅ Trade looks reasonable" if recommendations.empty?
        
        recommendations
      end

      def determine_best_stop_loss(ticker, position_value)
        volatility = ticker.price_variation_24h.abs
        
        case volatility
        when 0..3
          :conservative
        when 3..8
          :moderate
        else
          :aggressive
        end
      end

      def generate_ai_risk_insights(risk_data)
        return nil unless defined?(RubyLLM)
        
        prompt = build_ai_risk_analysis_prompt(risk_data)
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: prompt }],
            max_tokens: 300
          )
          
          {
            analysis: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI risk insights failed: #{e.message}")
          nil
        end
      end

      def build_ai_risk_analysis_prompt(risk_data)
        """
        Analyze this cryptocurrency portfolio risk assessment:
        
        Portfolio Value: #{risk_data[:portfolio_value]} CLP
        Holdings: #{risk_data[:currency_count]} currencies
        Risk Level: #{risk_data[:overall_risk][:level]} (#{risk_data[:overall_risk][:score]}/5)
        
        Risk Breakdown:
        - Max Position: #{risk_data[:basic_metrics][:max_position_percentage].round(1)}%
        - Diversification Score: #{risk_data[:advanced_metrics][:diversification_score].round(2)}
        - Volatility Score: #{risk_data[:advanced_metrics][:volatility_score]}
        - Correlation Risk: #{risk_data[:advanced_metrics][:correlation_risk]}
        
        Provide a concise risk analysis with:
        1. Key concerns and strengths
        2. Specific improvement recommendations
        3. Market outlook considerations
        
        Focus on actionable insights for Chilean crypto investors.
        """
      end
    end
  end
end