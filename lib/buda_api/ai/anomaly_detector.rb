# frozen_string_literal: true

module BudaApi
  module AI
    # AI-powered anomaly detection for trading patterns and market behavior
    class AnomalyDetector
      ANOMALY_TYPES = {
        price_spike: {
          severity: :high,
          description: "Unusual price movement detected",
          threshold: 15.0  # 15% price change
        },
        volume_anomaly: {
          severity: :medium,
          description: "Abnormal trading volume",
          threshold: 3.0   # 3x average volume
        },
        spread_anomaly: {
          severity: :medium,
          description: "Unusual bid-ask spread",
          threshold: 2.0   # 2x normal spread
        },
        trading_pattern: {
          severity: :low,
          description: "Unusual trading pattern detected",
          threshold: 1.5   # 1.5x normal pattern deviation
        },
        market_correlation: {
          severity: :medium,
          description: "Abnormal market correlation",
          threshold: 0.7   # Correlation coefficient threshold
        },
        whale_activity: {
          severity: :high,
          description: "Large order activity detected",
          threshold: 10.0  # 10x average order size
        }
      }.freeze

      def initialize(client, llm_provider: :openai)
        @client = client
        @llm = RubyLLM.new(
          provider: llm_provider,
          system_prompt: build_anomaly_system_prompt
        )
        @historical_data = {}
        
        BudaApi::Logger.info("Anomaly Detector initialized")
      end

      # Detect real-time anomalies across all markets
      #
      # @param options [Hash] detection options
      # @option options [Array<String>] :markets specific markets to monitor
      # @option options [Array<Symbol>] :anomaly_types types to detect
      # @option options [Boolean] :include_ai_analysis include AI insights
      # @return [Hash] anomaly detection results
      def detect_market_anomalies(options = {})
        markets = options[:markets] || BudaApi::Constants::Market::MAJOR
        anomaly_types = options[:anomaly_types] || ANOMALY_TYPES.keys
        include_ai = options[:include_ai_analysis] != false
        
        BudaApi::Logger.info("Detecting market anomalies across #{markets.length} markets")
        
        begin
          anomalies = []
          market_data = {}
          
          # Analyze each market
          markets.each do |market_id|
            market_analysis = analyze_market_for_anomalies(market_id, anomaly_types)
            market_data[market_id] = market_analysis[:data]
            
            if market_analysis[:anomalies].any?
              anomalies.concat(market_analysis[:anomalies])
            end
          end
          
          # Cross-market anomaly detection
          cross_market_anomalies = detect_cross_market_anomalies(market_data)
          anomalies.concat(cross_market_anomalies)
          
          # Sort by severity
          anomalies.sort_by! { |anomaly| anomaly[:severity_score] }.reverse!
          
          result = {
            type: :anomaly_detection,
            timestamp: Time.now,
            markets_analyzed: markets.length,
            anomalies_detected: anomalies.length,
            anomalies: anomalies,
            market_data: market_data,
            severity_summary: calculate_severity_summary(anomalies),
            recommendations: generate_anomaly_recommendations(anomalies)
          }
          
          # Add AI analysis if requested
          if include_ai && anomalies.any?
            result[:ai_analysis] = generate_ai_anomaly_analysis(result)
          end
          
          result
          
        rescue => e
          error_msg = "Anomaly detection failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :anomaly_detection_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Monitor specific market for anomalies in real-time
      #
      # @param market_id [String] market to monitor
      # @param duration [Integer] monitoring duration in seconds
      # @param callback [Proc] callback for real-time alerts
      # @return [Hash] monitoring results
      def monitor_market_realtime(market_id, duration = 3600, &callback)
        BudaApi::Logger.info("Starting real-time monitoring of #{market_id} for #{duration} seconds")
        
        start_time = Time.now
        anomalies_detected = []
        monitoring_active = true
        
        # Background monitoring thread
        monitoring_thread = Thread.new do
          while monitoring_active && (Time.now - start_time) < duration
            begin
              anomalies = detect_single_market_anomalies(market_id)
              
              anomalies.each do |anomaly|
                anomalies_detected << anomaly
                callback&.call(anomaly)
                
                # Log significant anomalies
                if anomaly[:severity_score] >= 7.0
                  BudaApi::Logger.warn("High severity anomaly detected in #{market_id}: #{anomaly[:type]}")
                end
              end
              
              # Check every 30 seconds
              sleep(30)
              
            rescue => e
              BudaApi::Logger.error("Real-time monitoring error: #{e.message}")
              sleep(60)  # Wait longer on error
            end
          end
        end
        
        # Return monitoring control object
        {
          type: :realtime_monitoring,
          market_id: market_id,
          start_time: start_time,
          duration: duration,
          thread: monitoring_thread,
          anomalies_detected: anomalies_detected,
          stop: -> { monitoring_active = false; monitoring_thread.join },
          status: -> { monitoring_active ? :active : :stopped }
        }
      end

      # Analyze historical data for patterns and anomalies
      #
      # @param market_id [String] market to analyze
      # @param lookback_hours [Integer] hours of history to analyze
      # @return [Hash] historical anomaly analysis
      def analyze_historical_anomalies(market_id, lookback_hours = 24)
        BudaApi::Logger.info("Analyzing historical anomalies for #{market_id} (#{lookback_hours}h lookback)")
        
        begin
          # Get historical ticker data (simulated - Buda API might not provide full historical data)
          historical_data = fetch_historical_data(market_id, lookback_hours)
          
          if historical_data.empty?
            return {
              type: :historical_analysis,
              market_id: market_id,
              message: "Insufficient historical data for analysis",
              timestamp: Time.now
            }
          end
          
          # Detect various anomaly patterns
          anomalies = []
          
          # Price spike detection
          price_anomalies = detect_price_spikes(historical_data)
          anomalies.concat(price_anomalies)
          
          # Volume pattern analysis
          volume_anomalies = detect_volume_anomalies(historical_data)
          anomalies.concat(volume_anomalies)
          
          # Trend anomalies
          trend_anomalies = detect_trend_anomalies(historical_data)
          anomalies.concat(trend_anomalies)
          
          # Statistical analysis
          statistical_anomalies = detect_statistical_anomalies(historical_data)
          anomalies.concat(statistical_anomalies)
          
          {
            type: :historical_analysis,
            market_id: market_id,
            lookback_hours: lookback_hours,
            data_points: historical_data.length,
            anomalies_found: anomalies.length,
            anomalies: anomalies.sort_by { |a| a[:severity_score] }.reverse,
            summary: generate_historical_summary(anomalies),
            timestamp: Time.now
          }
          
        rescue => e
          error_msg = "Historical anomaly analysis failed: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :historical_analysis_error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Set up automated alerts for specific anomaly types
      #
      # @param alert_config [Hash] alert configuration
      # @return [Hash] alert system status
      def setup_anomaly_alerts(alert_config = {})
        default_config = {
          markets: BudaApi::Constants::Market::MAJOR,
          anomaly_types: [:price_spike, :volume_anomaly, :whale_activity],
          severity_threshold: 6.0,
          notification_methods: [:log, :callback],
          check_interval: 60  # seconds
        }
        
        config = default_config.merge(alert_config)
        
        BudaApi::Logger.info("Setting up anomaly alerts with config: #{config}")
        
        {
          type: :alert_system,
          config: config,
          status: :configured,
          start_monitoring: -> { start_alert_monitoring(config) },
          timestamp: Time.now
        }
      end

      private

      def build_anomaly_system_prompt
        """
        You are an expert cryptocurrency market analyst specializing in anomaly detection.
        
        Your expertise includes:
        - Identifying unusual price movements and market patterns
        - Detecting trading volume anomalies
        - Recognizing whale activity and large order impacts
        - Analyzing market correlations and divergences
        - Assessing systemic risks and market manipulation
        - Understanding Chilean cryptocurrency market dynamics
        
        When analyzing anomalies:
        1. Consider both technical and fundamental factors
        2. Assess the potential market impact and risk level
        3. Provide clear explanations for detected anomalies
        4. Suggest appropriate responses or precautions
        5. Consider market context and recent events
        6. Differentiate between normal volatility and true anomalies
        
        Always prioritize accuracy and provide actionable insights.
        """
      end

      def analyze_market_for_anomalies(market_id, anomaly_types)
        begin
          # Get current market data
          ticker = @client.ticker(market_id)
          order_book = @client.order_book(market_id)
          
          market_data = {
            ticker: ticker,
            order_book: order_book,
            timestamp: Time.now
          }
          
          # Store historical reference
          store_market_reference(market_id, market_data)
          
          detected_anomalies = []
          
          # Check each requested anomaly type
          anomaly_types.each do |anomaly_type|
            anomaly = case anomaly_type
              when :price_spike
                detect_price_spike_anomaly(market_id, ticker)
              when :volume_anomaly
                detect_volume_anomaly(market_id, ticker)
              when :spread_anomaly
                detect_spread_anomaly(market_id, order_book)
              when :whale_activity
                detect_whale_activity(market_id, order_book)
              when :trading_pattern
                detect_trading_pattern_anomaly(market_id, ticker)
            end
            
            detected_anomalies << anomaly if anomaly
          end
          
          {
            market_id: market_id,
            data: market_data,
            anomalies: detected_anomalies
          }
          
        rescue => e
          BudaApi::Logger.warn("Failed to analyze #{market_id} for anomalies: #{e.message}")
          {
            market_id: market_id,
            data: nil,
            anomalies: [],
            error: e.message
          }
        end
      end

      def detect_price_spike_anomaly(market_id, ticker)
        change_24h = ticker.price_variation_24h.abs
        threshold = ANOMALY_TYPES[:price_spike][:threshold]
        
        return nil unless change_24h > threshold
        
        severity_score = calculate_severity_score(:price_spike, change_24h, threshold)
        
        {
          type: :price_spike,
          market_id: market_id,
          severity: determine_severity_level(severity_score),
          severity_score: severity_score,
          description: "Price spike detected: #{ticker.price_variation_24h.round(2)}% change",
          details: {
            current_price: ticker.last_price.amount,
            change_24h: ticker.price_variation_24h,
            threshold_exceeded: change_24h - threshold
          },
          timestamp: Time.now,
          recommendation: generate_price_spike_recommendation(change_24h, ticker.price_variation_24h)
        }
      end

      def detect_volume_anomaly(market_id, ticker)
        current_volume = ticker.volume.amount
        
        # Get historical average (simplified - using stored reference)
        historical_avg = get_historical_average_volume(market_id)
        return nil unless historical_avg && historical_avg > 0
        
        volume_ratio = current_volume / historical_avg
        threshold = ANOMALY_TYPES[:volume_anomaly][:threshold]
        
        return nil unless volume_ratio > threshold
        
        severity_score = calculate_severity_score(:volume_anomaly, volume_ratio, threshold)
        
        {
          type: :volume_anomaly,
          market_id: market_id,
          severity: determine_severity_level(severity_score),
          severity_score: severity_score,
          description: "Volume anomaly: #{volume_ratio.round(1)}x normal volume",
          details: {
            current_volume: current_volume,
            average_volume: historical_avg,
            volume_ratio: volume_ratio
          },
          timestamp: Time.now,
          recommendation: "Monitor for potential market movements or news events"
        }
      end

      def detect_spread_anomaly(market_id, order_book)
        return nil if order_book.asks.empty? || order_book.bids.empty?
        
        best_ask = order_book.asks.first.price
        best_bid = order_book.bids.first.price
        spread_percent = ((best_ask - best_bid) / best_ask * 100)
        
        # Get normal spread reference
        normal_spread = get_historical_average_spread(market_id)
        return nil unless normal_spread && normal_spread > 0
        
        spread_ratio = spread_percent / normal_spread
        threshold = ANOMALY_TYPES[:spread_anomaly][:threshold]
        
        return nil unless spread_ratio > threshold
        
        severity_score = calculate_severity_score(:spread_anomaly, spread_ratio, threshold)
        
        {
          type: :spread_anomaly,
          market_id: market_id,
          severity: determine_severity_level(severity_score),
          severity_score: severity_score,
          description: "Unusual spread: #{spread_percent.round(3)}% (#{spread_ratio.round(1)}x normal)",
          details: {
            current_spread: spread_percent,
            normal_spread: normal_spread,
            best_bid: best_bid,
            best_ask: best_ask
          },
          timestamp: Time.now,
          recommendation: "Caution with market orders - consider using limit orders"
        }
      end

      def detect_whale_activity(market_id, order_book)
        # Analyze order book for unusually large orders
        large_orders = []
        
        # Check asks
        order_book.asks.each do |ask|
          if ask.amount > calculate_whale_threshold(market_id, :ask)
            large_orders << { side: :ask, price: ask.price, amount: ask.amount }
          end
        end
        
        # Check bids
        order_book.bids.each do |bid|
          if bid.amount > calculate_whale_threshold(market_id, :bid)
            large_orders << { side: :bid, price: bid.price, amount: bid.amount }
          end
        end
        
        return nil if large_orders.empty?
        
        total_whale_value = large_orders.sum { |order| order[:amount] * order[:price] }
        severity_score = calculate_whale_severity(large_orders, total_whale_value)
        
        {
          type: :whale_activity,
          market_id: market_id,
          severity: determine_severity_level(severity_score),
          severity_score: severity_score,
          description: "Large order activity detected: #{large_orders.length} whale orders",
          details: {
            large_orders: large_orders,
            total_value: total_whale_value,
            largest_order: large_orders.max_by { |o| o[:amount] }
          },
          timestamp: Time.now,
          recommendation: "Monitor for potential price impact from large orders"
        }
      end

      def detect_trading_pattern_anomaly(market_id, ticker)
        # This would require more historical data for pattern recognition
        # Placeholder implementation
        
        change_24h = ticker.price_variation_24h.abs
        volume = ticker.volume.amount
        
        # Simple pattern check: high volume with low price change (accumulation/distribution)
        if volume > get_historical_average_volume(market_id).to_f * 2 && change_24h < 2.0
          severity_score = 5.0
          
          {
            type: :trading_pattern,
            market_id: market_id,
            severity: determine_severity_level(severity_score),
            severity_score: severity_score,
            description: "Accumulation/distribution pattern detected",
            details: {
              volume: volume,
              price_change: change_24h,
              pattern: "high_volume_low_change"
            },
            timestamp: Time.now,
            recommendation: "Potential institutional activity - monitor for breakout"
          }
        end
      end

      def detect_cross_market_anomalies(market_data)
        anomalies = []
        
        # Correlation anomalies between similar markets
        btc_markets = market_data.select { |market, _| market.start_with?("BTC-") }
        
        if btc_markets.length > 1
          correlation_anomaly = detect_correlation_anomaly(btc_markets)
          anomalies << correlation_anomaly if correlation_anomaly
        end
        
        # Market divergence detection
        divergence_anomaly = detect_market_divergence(market_data)
        anomalies << divergence_anomaly if divergence_anomaly
        
        anomalies
      end

      def detect_correlation_anomaly(btc_markets)
        # Simplified correlation analysis
        changes = btc_markets.values.map { |data| data[:ticker].price_variation_24h }
        
        # Check if changes have unusual divergence
        max_change = changes.max
        min_change = changes.min
        divergence = (max_change - min_change).abs
        
        if divergence > 10.0  # 10% divergence threshold
          {
            type: :market_correlation,
            severity: :medium,
            severity_score: 6.0,
            description: "Unusual BTC market divergence detected",
            details: {
              markets: btc_markets.keys,
              changes: changes,
              divergence: divergence
            },
            timestamp: Time.now,
            recommendation: "Investigate potential arbitrage opportunities"
          }
        end
      end

      def detect_market_divergence(market_data)
        # Check for overall market divergence from expected correlations
        all_changes = market_data.values.map { |data| data[:ticker].price_variation_24h rescue 0 }
        
        positive_markets = all_changes.count { |change| change > 0 }
        negative_markets = all_changes.count { |change| change < 0 }
        total_markets = all_changes.length
        
        # Unusual if markets are heavily skewed in one direction
        skew_ratio = [positive_markets, negative_markets].max / total_markets.to_f
        
        if skew_ratio > 0.8  # 80% of markets moving in same direction
          direction = positive_markets > negative_markets ? "bullish" : "bearish"
          
          {
            type: :market_divergence,
            severity: :low,
            severity_score: 4.0,
            description: "Strong #{direction} market consensus detected",
            details: {
              positive_markets: positive_markets,
              negative_markets: negative_markets,
              total_markets: total_markets,
              skew_ratio: skew_ratio,
              direction: direction
            },
            timestamp: Time.now,
            recommendation: "Monitor for potential trend reversal or continuation"
          }
        end
      end

      def store_market_reference(market_id, market_data)
        @historical_data[market_id] ||= []
        @historical_data[market_id] << {
          price: market_data[:ticker].last_price.amount,
          volume: market_data[:ticker].volume.amount,
          spread: calculate_current_spread(market_data[:order_book]),
          timestamp: Time.now
        }
        
        # Keep only last 100 data points
        @historical_data[market_id] = @historical_data[market_id].last(100)
      end

      def calculate_current_spread(order_book)
        return 0.0 if order_book.asks.empty? || order_book.bids.empty?
        
        best_ask = order_book.asks.first.price
        best_bid = order_book.bids.first.price
        ((best_ask - best_bid) / best_ask * 100)
      end

      def get_historical_average_volume(market_id)
        history = @historical_data[market_id]
        return nil if !history || history.empty?
        
        volumes = history.map { |data| data[:volume] }
        volumes.sum / volumes.length.to_f
      end

      def get_historical_average_spread(market_id)
        history = @historical_data[market_id]
        return nil if !history || history.empty?
        
        spreads = history.map { |data| data[:spread] }
        spreads.sum / spreads.length.to_f
      end

      def calculate_whale_threshold(market_id, side)
        # Simplified whale detection - would use more sophisticated analysis in production
        avg_volume = get_historical_average_volume(market_id) || 1000.0
        avg_volume * 0.1  # 10% of daily volume in single order
      end

      def calculate_severity_score(anomaly_type, value, threshold)
        config = ANOMALY_TYPES[anomaly_type]
        base_score = case config[:severity]
          when :low then 3.0
          when :medium then 5.0
          when :high then 7.0
        end
        
        # Adjust based on how much threshold was exceeded
        excess_ratio = value / threshold
        adjusted_score = base_score * excess_ratio
        
        [adjusted_score, 10.0].min  # Cap at 10.0
      end

      def calculate_whale_severity(large_orders, total_value)
        # Base severity on number and size of whale orders
        order_count_factor = [large_orders.length / 3.0, 1.0].min
        value_factor = Math.log10([total_value / 100000.0, 1.0].max)
        
        5.0 + (order_count_factor * 2.0) + (value_factor * 1.5)
      end

      def determine_severity_level(score)
        case score
        when 0..3 then :low
        when 3..6 then :medium
        when 6..8 then :high
        else :critical
        end
      end

      def calculate_severity_summary(anomalies)
        {
          critical: anomalies.count { |a| a[:severity] == :critical },
          high: anomalies.count { |a| a[:severity] == :high },
          medium: anomalies.count { |a| a[:severity] == :medium },
          low: anomalies.count { |a| a[:severity] == :low }
        }
      end

      def generate_anomaly_recommendations(anomalies)
        recommendations = []
        
        if anomalies.any? { |a| a[:severity] == :critical }
          recommendations << "🚨 CRITICAL: Immediate attention required - consider halting trading"
        end
        
        if anomalies.count { |a| a[:type] == :price_spike } > 2
          recommendations << "📈 Multiple price spikes detected - market volatility high"
        end
        
        if anomalies.any? { |a| a[:type] == :whale_activity }
          recommendations << "🐋 Large order activity - monitor for price impact"
        end
        
        if anomalies.count { |a| a[:severity] == :high } > 3
          recommendations << "⚠️ Multiple high-severity anomalies - increased caution advised"
        end
        
        recommendations << "✅ Continue normal monitoring" if recommendations.empty?
        
        recommendations
      end

      def generate_price_spike_recommendation(change_magnitude, change_direction)
        if change_magnitude > 20.0
          if change_direction > 0
            "🚀 Major pump detected - consider taking profits or wait for pullback"
          else
            "📉 Major dump detected - avoid panic selling, look for support levels"
          end
        elsif change_magnitude > 10.0
          "📊 Significant price movement - verify with news and volume"
        else
          "👀 Monitor for continuation or reversal"
        end
      end

      def detect_single_market_anomalies(market_id)
        analysis = analyze_market_for_anomalies(market_id, ANOMALY_TYPES.keys)
        analysis[:anomalies]
      end

      def start_alert_monitoring(config)
        # Implementation would start background monitoring with the given configuration
        BudaApi::Logger.info("Starting alert monitoring with config: #{config}")
        {
          status: :monitoring_started,
          config: config,
          timestamp: Time.now
        }
      end

      # Historical data analysis methods (simplified implementations)
      def fetch_historical_data(market_id, lookback_hours)
        # In a real implementation, this would fetch actual historical data
        # For now, return empty array as Buda API might not provide extensive historical data
        []
      end

      def detect_price_spikes(historical_data)
        []  # Placeholder
      end

      def detect_volume_anomalies(historical_data)
        []  # Placeholder
      end

      def detect_trend_anomalies(historical_data)
        []  # Placeholder
      end

      def detect_statistical_anomalies(historical_data)
        []  # Placeholder
      end

      def generate_historical_summary(anomalies)
        {
          total_anomalies: anomalies.length,
          by_type: anomalies.group_by { |a| a[:type] }.transform_values(&:length),
          avg_severity: anomalies.map { |a| a[:severity_score] }.sum / [anomalies.length, 1].max
        }
      end

      def generate_ai_anomaly_analysis(result)
        return nil unless defined?(RubyLLM)
        
        prompt = build_ai_anomaly_prompt(result)
        
        begin
          response = @llm.complete(
            messages: [{ role: "user", content: prompt }],
            max_tokens: 400
          )
          
          {
            analysis: response.content,
            generated_at: Time.now
          }
        rescue => e
          BudaApi::Logger.error("AI anomaly analysis failed: #{e.message}")
          nil
        end
      end

      def build_ai_anomaly_prompt(result)
        anomaly_summary = result[:anomalies].map do |anomaly|
          "- #{anomaly[:type]}: #{anomaly[:description]} (Severity: #{anomaly[:severity]})"
        end.join("\n")
        
        """
        Analyze these cryptocurrency market anomalies detected on the Buda exchange:
        
        Markets Analyzed: #{result[:markets_analyzed]}
        Total Anomalies: #{result[:anomalies_detected]}
        
        Detected Anomalies:
        #{anomaly_summary}
        
        Severity Summary:
        - Critical: #{result[:severity_summary][:critical]}
        - High: #{result[:severity_summary][:high]}
        - Medium: #{result[:severity_summary][:medium]}
        - Low: #{result[:severity_summary][:low]}
        
        Please provide:
        1. Overall market risk assessment
        2. Potential causes for the anomalies
        3. Specific trading recommendations
        4. Risk mitigation strategies
        
        Focus on actionable insights for Chilean crypto traders.
        """
      end
    end
  end
end