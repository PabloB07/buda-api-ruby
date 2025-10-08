# frozen_string_literal: true

module BudaApi
  module AI
    # Natural language interface for trading operations
    class NaturalLanguageTrader
      TRADING_FUNCTIONS = [
        {
          name: "place_order",
          description: "Place a buy or sell order on the exchange",
          parameters: {
            type: "object",
            properties: {
              market_id: { 
                type: "string", 
                description: "Trading pair (e.g., BTC-CLP)",
                enum: BudaApi::Constants::Market::ALL
              },
              side: { 
                type: "string", 
                enum: ["buy", "sell"],
                description: "Whether to buy or sell"
              },
              amount: { 
                type: "number", 
                description: "Amount to trade (in base currency)"
              },
              price: { 
                type: "number", 
                description: "Price per unit (optional for market orders)"
              },
              order_type: { 
                type: "string", 
                enum: ["market", "limit"],
                description: "Order type - market executes immediately, limit waits for price"
              }
            },
            required: ["market_id", "side", "amount"]
          }
        },
        {
          name: "check_balance",
          description: "Check account balance for a specific currency",
          parameters: {
            type: "object",
            properties: {
              currency: { 
                type: "string", 
                description: "Currency code (e.g., BTC, CLP)",
                enum: BudaApi::Constants::Currency::ALL
              }
            },
            required: ["currency"]
          }
        },
        {
          name: "get_market_data",
          description: "Get current market data including price and order book",
          parameters: {
            type: "object",
            properties: {
              market_id: { 
                type: "string", 
                description: "Trading pair (e.g., BTC-CLP)",
                enum: BudaApi::Constants::Market::ALL
              }
            },
            required: ["market_id"]
          }
        },
        {
          name: "cancel_order",
          description: "Cancel an existing order",
          parameters: {
            type: "object",
            properties: {
              order_id: {
                type: "integer",
                description: "ID of the order to cancel"
              }
            },
            required: ["order_id"]
          }
        },
        {
          name: "get_order_history",
          description: "Get recent order history for a market",
          parameters: {
            type: "object",
            properties: {
              market_id: {
                type: "string",
                description: "Trading pair (e.g., BTC-CLP)",
                enum: BudaApi::Constants::Market::ALL
              },
              limit: {
                type: "integer",
                description: "Number of orders to retrieve (max 100)",
                maximum: 100
              }
            },
            required: ["market_id"]
          }
        },
        {
          name: "get_quotation",
          description: "Get price quotation for a potential trade",
          parameters: {
            type: "object",
            properties: {
              market_id: {
                type: "string", 
                description: "Trading pair (e.g., BTC-CLP)",
                enum: BudaApi::Constants::Market::ALL
              },
              side: {
                type: "string",
                enum: ["buy", "sell"],
                description: "Whether you want to buy or sell"
              },
              amount: {
                type: "number",
                description: "Amount you want to trade"
              }
            },
            required: ["market_id", "side", "amount"]
          }
        }
      ].freeze

      def initialize(client, llm_provider: :openai)
        @client = client
        @llm = RubyLLM.new(
          provider: llm_provider,
          functions: TRADING_FUNCTIONS
        )
        @conversation_history = []
        
        BudaApi::Logger.info("Natural Language Trader initialized")
      end

      # Execute a natural language trading command
      #
      # @param input [String] natural language command
      # @param confirm_trades [Boolean] whether to confirm before placing orders
      # @return [Hash] execution result
      # @example
      #   trader = BudaApi.natural_language_trader(client)
      #   result = trader.execute_command("Check my BTC balance")
      #   result = trader.execute_command("Buy 0.001 BTC at market price")
      def execute_command(input, confirm_trades: true)
        BudaApi::Logger.info("Processing natural language command: #{input}")
        
        # Add to conversation history
        @conversation_history << { role: "user", content: input }
        
        begin
          response = @llm.complete(
            messages: build_conversation_messages,
            system_prompt: build_system_prompt,
            max_tokens: 500
          )
          
          # Add assistant response to history
          @conversation_history << { role: "assistant", content: response.content }
          
          if response.function_call
            result = execute_function_with_confirmation(response.function_call, confirm_trades)
            
            # Add function result to conversation
            @conversation_history << {
              role: "function", 
              name: response.function_call.name,
              content: result.to_json
            }
            
            result
          else
            {
              type: :text_response,
              content: response.content,
              timestamp: Time.now
            }
          end
          
        rescue => e
          error_msg = "Failed to process command: #{e.message}"
          BudaApi::Logger.error(error_msg)
          
          {
            type: :error,
            error: error_msg,
            timestamp: Time.now
          }
        end
      end

      # Clear conversation history
      def clear_history
        @conversation_history.clear
        BudaApi::Logger.info("Conversation history cleared")
      end

      # Get conversation history
      # @return [Array<Hash>] conversation messages
      def conversation_history
        @conversation_history.dup
      end

      # Process batch commands
      # @param commands [Array<String>] list of natural language commands
      # @param confirm_trades [Boolean] whether to confirm trades
      # @return [Array<Hash>] results for each command
      def execute_batch(commands, confirm_trades: true)
        results = []
        
        commands.each_with_index do |command, index|
          BudaApi::Logger.info("Processing batch command #{index + 1}/#{commands.length}")
          result = execute_command(command, confirm_trades: confirm_trades)
          results << result
          
          # Add small delay between commands to avoid rate limiting
          sleep(0.5) unless index == commands.length - 1
        end
        
        results
      end

      private

      def build_system_prompt
        """
        You are a cryptocurrency trading assistant for the Buda exchange in Chile.
        
        CAPABILITIES:
        - Check account balances for any supported currency
        - Get real-time market data and prices
        - Place buy and sell orders (market and limit orders)
        - Cancel existing orders
        - Get order history and trading records
        - Provide price quotations for potential trades
        
        SUPPORTED MARKETS: #{BudaApi::Constants::Market::ALL.join(', ')}
        SUPPORTED CURRENCIES: #{BudaApi::Constants::Currency::ALL.join(', ')}
        
        GUIDELINES:
        1. Always confirm risky operations like placing orders
        2. Be precise with numbers and avoid rounding errors
        3. Explain what each function does before executing
        4. Provide helpful context about market conditions
        5. Use Chilean Peso (CLP) as the default quote currency
        6. Warn about risks and fees when appropriate
        
        IMPORTANT SAFETY RULES:
        - Always double-check order parameters
        - Warn about large orders that could impact the market
        - Suggest limit orders for better price control
        - Remind users about trading fees
        
        When users ask about prices, trading, or market data, use the appropriate functions.
        Always be helpful, accurate, and prioritize user safety.
        """
      end

      def build_conversation_messages
        # Keep last 10 messages to maintain context while avoiding token limits
        recent_history = @conversation_history.last(10)
        
        messages = []
        recent_history.each do |msg|
          case msg[:role]
          when "user", "assistant"
            messages << { role: msg[:role], content: msg[:content] }
          when "function"
            messages << {
              role: "function",
              name: msg[:name],
              content: msg[:content]
            }
          end
        end
        
        messages
      end

      def execute_function_with_confirmation(function_call, confirm_trades)
        function_name = function_call.name
        arguments = function_call.arguments
        
        BudaApi::Logger.info("Executing function: #{function_name} with args: #{arguments}")
        
        # Check if this is a trading operation that needs confirmation
        if trading_function?(function_name) && confirm_trades
          confirmation = request_confirmation(function_name, arguments)
          return confirmation unless confirmation[:confirmed]
        end
        
        case function_name
        when "place_order"
          place_order_from_params(arguments)
        when "check_balance"
          check_balance_from_params(arguments)
        when "get_market_data"
          get_market_data_from_params(arguments)
        when "cancel_order"
          cancel_order_from_params(arguments)
        when "get_order_history"
          get_order_history_from_params(arguments)
        when "get_quotation"
          get_quotation_from_params(arguments)
        else
          {
            type: :error,
            error: "Unknown function: #{function_name}",
            timestamp: Time.now
          }
        end
      end

      def trading_function?(function_name)
        %w[place_order cancel_order].include?(function_name)
      end

      def request_confirmation(function_name, arguments)
        case function_name
        when "place_order"
          {
            type: :confirmation_required,
            message: "⚠️ About to place #{arguments['side']} order: #{arguments['amount']} #{arguments['market_id']} at #{arguments['price'] || 'market price'}. Confirm?",
            function: function_name,
            arguments: arguments,
            confirmed: false,
            timestamp: Time.now
          }
        when "cancel_order"
          {
            type: :confirmation_required,
            message: "⚠️ About to cancel order ##{arguments['order_id']}. Confirm?",
            function: function_name,
            arguments: arguments,
            confirmed: false,
            timestamp: Time.now
          }
        end
      end

      def place_order_from_params(params)
        market_id = params["market_id"]
        side = params["side"]
        amount = params["amount"].to_f
        price = params["price"]&.to_f
        order_type = params["order_type"] || (price ? "limit" : "market")
        
        # Convert side to Buda API format
        buda_order_type = side == "buy" ? "Bid" : "Ask"
        buda_price_type = order_type == "market" ? "market" : "limit"
        
        begin
          order = @client.place_order(market_id, buda_order_type, buda_price_type, amount, price)
          
          {
            type: :order_placed,
            order_id: order.id,
            market_id: market_id,
            side: side,
            amount: amount,
            price: price,
            order_type: order_type,
            status: order.state,
            message: "✅ Order placed successfully! Order ID: #{order.id}",
            data: order,
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :order_failed,
            error: e.message,
            market_id: market_id,
            side: side,
            amount: amount,
            message: "❌ Failed to place order: #{e.message}",
            timestamp: Time.now
          }
        end
      end

      def check_balance_from_params(params)
        currency = params["currency"]
        
        begin
          balance = @client.balance(currency)
          
          {
            type: :balance_info,
            currency: currency,
            total: balance.amount.amount,
            available: balance.available_amount.amount,
            frozen: balance.frozen_amount.amount,
            pending_withdrawals: balance.pending_withdraw_amount.amount,
            message: "💰 #{currency} Balance: #{balance.available_amount} available, #{balance.frozen_amount} frozen",
            data: balance,
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :balance_error,
            error: e.message,
            currency: currency,
            message: "❌ Failed to get balance: #{e.message}",
            timestamp: Time.now
          }
        end
      end

      def get_market_data_from_params(params)
        market_id = params["market_id"]
        
        begin
          ticker = @client.ticker(market_id)
          order_book = @client.order_book(market_id)
          
          {
            type: :market_data,
            market_id: market_id,
            price: ticker.last_price.amount,
            change_24h: ticker.price_variation_24h,
            volume: ticker.volume.amount,
            best_ask: order_book.best_ask.price,
            best_bid: order_book.best_bid.price,
            spread: order_book.spread_percentage,
            message: "📊 #{market_id}: #{ticker.last_price} (#{ticker.price_variation_24h > 0 ? '+' : ''}#{ticker.price_variation_24h}%)",
            data: { ticker: ticker, order_book: order_book },
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :market_data_error,
            error: e.message,
            market_id: market_id,
            message: "❌ Failed to get market data: #{e.message}",
            timestamp: Time.now
          }
        end
      end

      def cancel_order_from_params(params)
        order_id = params["order_id"]
        
        begin
          cancelled_order = @client.cancel_order(order_id)
          
          {
            type: :order_cancelled,
            order_id: order_id,
            status: cancelled_order.state,
            message: "✅ Order ##{order_id} cancelled successfully",
            data: cancelled_order,
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :cancel_failed,
            error: e.message,
            order_id: order_id,
            message: "❌ Failed to cancel order: #{e.message}",
            timestamp: Time.now
          }
        end
      end

      def get_order_history_from_params(params)
        market_id = params["market_id"]
        limit = [params["limit"]&.to_i || 10, 100].min
        
        begin
          orders_result = @client.orders(market_id, per_page: limit)
          
          {
            type: :order_history,
            market_id: market_id,
            orders_count: orders_result.count,
            orders: orders_result.orders.map do |order|
              {
                id: order.id,
                type: order.type,
                amount: order.amount.amount,
                price: order.limit&.amount,
                state: order.state,
                created_at: order.created_at
              }
            end,
            message: "📋 Found #{orders_result.count} orders for #{market_id}",
            data: orders_result,
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :history_error,
            error: e.message,
            market_id: market_id,
            message: "❌ Failed to get order history: #{e.message}",
            timestamp: Time.now
          }
        end
      end

      def get_quotation_from_params(params)
        market_id = params["market_id"]
        side = params["side"]
        amount = params["amount"].to_f
        
        # Convert side to quotation type
        quotation_type = side == "buy" ? "bid_given_size" : "ask_given_size"
        
        begin
          quotation = @client.quotation(market_id, quotation_type, amount)
          
          {
            type: :quotation,
            market_id: market_id,
            side: side,
            amount: amount,
            estimated_cost: quotation.quote_balance_change.amount,
            fee: quotation.fee.amount,
            message: "💱 To #{side} #{amount} #{market_id.split('-').first}: ~#{quotation.quote_balance_change} (fee: #{quotation.fee})",
            data: quotation,
            timestamp: Time.now
          }
        rescue BudaApi::ApiError => e
          {
            type: :quotation_error,
            error: e.message,
            market_id: market_id,
            message: "❌ Failed to get quotation: #{e.message}",
            timestamp: Time.now
          }
        end
      end
    end
  end
end