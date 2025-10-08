# frozen_string_literal: true

module BudaApi
  # Authenticated API client for endpoints that require API key authentication
  class AuthenticatedClient < PublicClient
    attr_reader :api_key, :api_secret

    # Initialize an authenticated client
    #
    # @param api_key [String] your API key
    # @param api_secret [String] your API secret  
    # @param options [Hash] additional options
    # @example
    #   client = BudaApi::AuthenticatedClient.new(
    #     api_key: "your_api_key",
    #     api_secret: "your_api_secret",
    #     debug_mode: true
    #   )
    def initialize(api_key:, api_secret:, **options)
      validate_credentials(api_key, api_secret)
      
      @api_key = api_key
      @api_secret = api_secret
      
      super(options)
      
      BudaApi::Logger.info("Authenticated client initialized")
    end

    # Get balance for a specific currency
    #
    # @param currency [String] currency code
    # @return [Balance] current balance information
    # @example
    #   balance = client.balance("BTC")
    #   puts "Available: #{balance.available_amount}"
    #   puts "Frozen: #{balance.frozen_amount}"
    def balance(currency)
      validate_required_params({ currency: currency }, [:currency])
      validate_param_values({ currency: currency }, { currency: Currency::ALL })

      BudaApi::Logger.info("Fetching balance for #{currency}")
      
      response = get("balances/#{currency}")
      Balance.new(response["balance"])
    end

    # Get balance events with pagination
    #
    # @param currencies [Array<String>] list of currencies to filter by
    # @param event_names [Array<String>] list of event types to filter by
    # @param page [Integer, nil] page number
    # @param per_page [Integer, nil] items per page
    # @param relevant [Boolean, nil] filter for relevant events only
    # @return [Hash] balance events with pagination info
    def balance_events(currencies:, event_names:, page: nil, per_page: nil, relevant: nil)
      validate_required_params({ 
        currencies: currencies, 
        event_names: event_names 
      }, [:currencies, :event_names])

      # Validate currency and event parameters
      currencies.each do |currency|
        validate_param_values({ currency: currency }, { currency: Currency::ALL })
      end
      
      event_names.each do |event|
        validate_param_values({ event: event }, { event: BalanceEvent::ALL })
      end

      params = normalize_params({
        "currencies[]" => currencies,
        "event_names[]" => event_names,
        page: page,
        per: per_page,
        relevant: relevant
      })

      BudaApi::Logger.info("Fetching balance events with params: #{params}")
      
      response = get("balance_events", params)
      {
        events: response["balance_events"] || [],
        total_count: response["total_count"]
      }
    end

    # Place a new order
    #
    # @param market_id [String] market identifier
    # @param order_type [String] "Ask" (sell) or "Bid" (buy)
    # @param price_type [String] "market" or "limit"
    # @param amount [Float] amount to trade
    # @param limit [Float, nil] limit price (required for limit orders)
    # @return [Order] created order
    # @example
    #   # Place a limit buy order
    #   order = client.place_order("BTC-CLP", "Bid", "limit", 0.001, 50000000)
    #   
    #   # Place a market sell order
    #   order = client.place_order("BTC-CLP", "Ask", "market", 0.001)
    def place_order(market_id, order_type, price_type, amount, limit = nil)
      validate_required_params({
        market_id: market_id,
        order_type: order_type, 
        price_type: price_type,
        amount: amount
      }, [:market_id, :order_type, :price_type, :amount])

      validate_param_values({
        market_id: market_id,
        order_type: order_type,
        price_type: price_type
      }, {
        market_id: Market::ALL,
        order_type: OrderType::ALL,
        price_type: PriceType::ALL
      })

      if price_type == PriceType::LIMIT && limit.nil?
        raise ValidationError, "Limit price is required for limit orders"
      end

      order_payload = {
        type: order_type,
        price_type: price_type,
        amount: amount.to_s
      }
      order_payload[:limit] = limit.to_s if limit

      BudaApi::Logger.info("Placing #{order_type} #{price_type} order for #{amount} on #{market_id}")
      
      response = post("markets/#{market_id}/orders", body: order_payload)
      Order.new(response["order"])
    end

    # Get orders with pagination
    #
    # @param market_id [String] market identifier
    # @param page [Integer, nil] page number
    # @param per_page [Integer, nil] orders per page (max 300)
    # @param state [String, nil] filter by order state
    # @param minimum_exchanged [Float, nil] minimum exchanged amount filter
    # @return [OrderPages] paginated orders
    # @example
    #   orders = client.orders("BTC-CLP", page: 1, per_page: 50, state: "traded")
    #   puts "Found #{orders.count} orders on page #{orders.meta.current_page}"
    def orders(market_id, page: nil, per_page: nil, state: nil, minimum_exchanged: nil)
      validate_required_params({ market_id: market_id }, [:market_id])
      validate_param_values({ market_id: market_id }, { market_id: Market::ALL })

      if per_page && per_page > Limits::ORDERS_PER_PAGE
        raise ValidationError, "per_page cannot exceed #{Limits::ORDERS_PER_PAGE}"
      end

      validate_param_values({ state: state }, { state: OrderState::ALL }) if state

      params = normalize_params({
        per: per_page,
        page: page,
        state: state,
        minimum_exchanged: minimum_exchanged
      })

      BudaApi::Logger.info("Fetching orders for #{market_id} with params: #{params}")
      
      response = get("markets/#{market_id}/orders", params)
      OrderPages.new(response["orders"] || [], response["meta"])
    end

    # Get specific order details
    #
    # @param order_id [Integer] order ID
    # @return [Order] order details
    # @example
    #   order = client.order_details(123456)
    #   puts "Order state: #{order.state}"
    #   puts "Filled: #{order.filled_percentage}%"
    def order_details(order_id)
      validate_required_params({ order_id: order_id }, [:order_id])

      BudaApi::Logger.info("Fetching details for order #{order_id}")
      
      response = get("orders/#{order_id}")
      Order.new(response["order"])
    end

    # Cancel an order
    #
    # @param order_id [Integer] order ID to cancel
    # @return [Order] updated order with canceling state
    # @example
    #   cancelled_order = client.cancel_order(123456)
    #   puts "Order #{cancelled_order.id} is now #{cancelled_order.state}"
    def cancel_order(order_id)
      validate_required_params({ order_id: order_id }, [:order_id])

      BudaApi::Logger.info("Cancelling order #{order_id}")
      
      response = put("orders/#{order_id}", body: { state: OrderState::CANCELING })
      Order.new(response["order"])
    end

    # Batch order operations (cancel and/or place multiple orders)
    #
    # @param cancel_orders [Array<Integer>] list of order IDs to cancel
    # @param place_orders [Array<Hash>] list of order specifications to place
    # @return [Hash] batch operation results
    # @example
    #   # Cancel some orders and place new ones atomically
    #   result = client.batch_orders(
    #     cancel_orders: [123, 456],
    #     place_orders: [
    #       { type: "Bid", price_type: "limit", amount: "0.001", limit: "50000" }
    #     ]
    #   )
    def batch_orders(cancel_orders: [], place_orders: [])
      diff_operations = []

      cancel_orders.each do |order_id|
        diff_operations << { mode: "cancel", order_id: order_id }
      end

      place_orders.each do |order_spec|
        diff_operations << { mode: "place", order: order_spec }
      end

      if diff_operations.empty?
        raise ValidationError, "At least one cancel or place operation must be specified"
      end

      BudaApi::Logger.info("Executing batch order operations: #{diff_operations.length} operations")
      
      response = post("orders", body: { diff: diff_operations })
      response
    end

    # Get withdrawals with pagination
    #
    # @param currency [String] currency code
    # @param page [Integer, nil] page number
    # @param per_page [Integer, nil] withdrawals per page
    # @param state [String, nil] filter by withdrawal state
    # @return [Hash] withdrawals with pagination metadata
    # @example
    #   withdrawals = client.withdrawals("BTC", page: 1, per_page: 20)
    def withdrawals(currency, page: nil, per_page: nil, state: nil)
      validate_required_params({ currency: currency }, [:currency])
      validate_param_values({ currency: currency }, { currency: Currency::ALL })

      if per_page && per_page > Limits::TRANSFERS_PER_PAGE
        raise ValidationError, "per_page cannot exceed #{Limits::TRANSFERS_PER_PAGE}"
      end

      params = normalize_params({
        per: per_page,
        page: page,
        state: state
      })

      BudaApi::Logger.info("Fetching withdrawals for #{currency} with params: #{params}")
      
      response = get("currencies/#{currency}/withdrawals", params)
      {
        withdrawals: (response["withdrawals"] || []).map { |w| Withdrawal.new(w) },
        meta: PaginationMeta.new(response["meta"] || {})
      }
    end

    # Get deposits with pagination
    #
    # @param currency [String] currency code  
    # @param page [Integer, nil] page number
    # @param per_page [Integer, nil] deposits per page
    # @param state [String, nil] filter by deposit state
    # @return [Hash] deposits with pagination metadata
    # @example
    #   deposits = client.deposits("BTC", page: 1, per_page: 20)
    def deposits(currency, page: nil, per_page: nil, state: nil)
      validate_required_params({ currency: currency }, [:currency])
      validate_param_values({ currency: currency }, { currency: Currency::ALL })

      if per_page && per_page > Limits::TRANSFERS_PER_PAGE
        raise ValidationError, "per_page cannot exceed #{Limits::TRANSFERS_PER_PAGE}"
      end

      params = normalize_params({
        per: per_page,
        page: page,
        state: state
      })

      BudaApi::Logger.info("Fetching deposits for #{currency} with params: #{params}")
      
      response = get("currencies/#{currency}/deposits", params)
      {
        deposits: (response["deposits"] || []).map { |d| Deposit.new(d) },
        meta: PaginationMeta.new(response["meta"] || {})
      }
    end

    # Create a withdrawal
    #
    # @param currency [String] currency to withdraw
    # @param amount [Float] amount to withdraw  
    # @param target_address [String] destination address
    # @param amount_includes_fee [Boolean] whether amount includes the fee
    # @param simulate [Boolean] whether to simulate the withdrawal (not execute)
    # @return [Withdrawal] withdrawal details
    # @example
    #   # Simulate a withdrawal first
    #   simulation = client.withdrawal("BTC", 0.01, "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa", simulate: true)
    #   puts "Fee would be: #{simulation.fee}"
    #   
    #   # Execute the actual withdrawal
    #   withdrawal = client.withdrawal("BTC", 0.01, "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa")
    def withdrawal(currency, amount, target_address, amount_includes_fee: true, simulate: false)
      validate_required_params({
        currency: currency,
        amount: amount,
        target_address: target_address
      }, [:currency, :amount, :target_address])
      
      validate_param_values({ currency: currency }, { currency: Currency::ALL })

      withdrawal_payload = {
        withdrawal_data: {
          target_address: target_address
        },
        amount: amount.to_s,
        currency: currency,
        simulate: simulate,
        amount_includes_fee: amount_includes_fee
      }

      action = simulate ? "Simulating" : "Creating"
      BudaApi::Logger.info("#{action} withdrawal: #{amount} #{currency} to #{target_address}")
      
      response = post("currencies/#{currency}/withdrawals", body: withdrawal_payload)
      Withdrawal.new(response["withdrawal"])
    end

    # Simulate a withdrawal (without executing)
    #
    # @param currency [String] currency to withdraw
    # @param amount [Float] amount to withdraw
    # @param amount_includes_fee [Boolean] whether amount includes the fee  
    # @return [Withdrawal] simulated withdrawal with fee information
    # @example
    #   simulation = client.simulate_withdrawal("BTC", 0.01)
    #   puts "Withdrawal fee: #{simulation.fee}"
    #   puts "You will receive: #{simulation.amount.amount - simulation.fee.amount}"
    def simulate_withdrawal(currency, amount, amount_includes_fee: true)
      withdrawal(currency, amount, nil, amount_includes_fee: amount_includes_fee, simulate: true)
    end

    private

    def validate_credentials(api_key, api_secret)
      if api_key.nil? || api_key.empty?
        raise ConfigurationError, "API key is required for authenticated client"
      end
      
      if api_secret.nil? || api_secret.empty?
        raise ConfigurationError, "API secret is required for authenticated client"  
      end
    end

    # Add HMAC authentication headers to requests
    def add_authentication_headers(method, path, body, headers)
      nonce = generate_nonce
      message = build_signature_message(method, path, body, nonce)
      signature = generate_signature(message)

      headers.merge({
        "X-SBTC-APIKEY" => @api_key,
        "X-SBTC-NONCE" => nonce,
        "X-SBTC-SIGNATURE" => signature,
        "Content-Type" => "application/json"
      })
    end

    def generate_nonce
      (Time.now.to_f * 1000000).to_i.to_s
    end

    def build_signature_message(method, path, body, nonce)
      components = [method.upcase, path]
      
      if body && !body.empty?
        encoded_body = Base64.strict_encode64(body.to_json)
        components << encoded_body
      end
      
      components << nonce
      components.join(" ")
    end

    def generate_signature(message)
      OpenSSL::HMAC.hexdigest("sha384", @api_secret, message)
    end
  end
end