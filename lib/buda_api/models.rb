# frozen_string_literal: true

require "ostruct"
require "time"

module BudaApi
  # Data models for API responses
  module Models
    # Base model class with common functionality
    class BaseModel
      def initialize(data = {})
        @data = data.is_a?(Hash) ? data : {}
        @raw_data = @data.dup
      end

      # Access to raw API response data
      def raw
        @raw_data
      end

      # Convert to hash
      def to_h
        @data
      end

      # Convert to JSON  
      def to_json(*args)
        @data.to_json(*args)
      end

      private

      def parse_datetime(datetime_string)
        return nil if datetime_string.nil? || datetime_string.empty?
        
        Time.parse(datetime_string)
      rescue ArgumentError
        nil
      end

      def parse_amount(amount_data)
        return nil unless amount_data.is_a?(Hash)
        
        Amount.new(amount_data)
      end
    end

    # Amount model for currency amounts
    class Amount < BaseModel
      def initialize(data)
        super(data)
        @amount = data["amount"]&.to_f || 0.0
        @currency = data["currency"]
      end

      attr_reader :amount, :currency

      def to_s
        "#{@amount} #{@currency}"
      end

      def ==(other)
        other.is_a?(Amount) && 
        @amount == other.amount && 
        @currency == other.currency
      end
    end

    # Market model
    class Market < BaseModel
      def initialize(data)
        super(data)
        @id = data["id"]
        @name = data["name"] 
        @base_currency = data["base_currency"]
        @quote_currency = data["quote_currency"]
        @minimum_order_amount = parse_amount(data["minimum_order_amount"])
      end

      attr_reader :id, :name, :base_currency, :quote_currency, :minimum_order_amount
    end

    # Ticker model
    class Ticker < BaseModel  
      def initialize(data)
        super(data)
        @last_price = parse_amount(data["last_price"])
        @min_ask = parse_amount(data["min_ask"])
        @max_bid = parse_amount(data["max_bid"])
        @volume = parse_amount(data["volume"])
        @price_variation_24h = data["price_variation_24h"]&.to_f
        @price_variation_7d = data["price_variation_7d"]&.to_f
      end

      attr_reader :last_price, :min_ask, :max_bid, :volume, 
                  :price_variation_24h, :price_variation_7d
    end

    # Order book entry model
    class OrderBookEntry < BaseModel
      def initialize(data)
        super(data)
        if data.is_a?(Array) && data.length >= 2
          @price = data[0].to_f
          @amount = data[1].to_f
        else
          @price = data["price"]&.to_f || 0.0
          @amount = data["amount"]&.to_f || 0.0
        end
      end

      attr_reader :price, :amount

      def total
        @price * @amount
      end
    end

    # Order book model
    class OrderBook < BaseModel
      def initialize(data)
        super(data)
        @asks = (data["asks"] || []).map { |entry| OrderBookEntry.new(entry) }
        @bids = (data["bids"] || []).map { |entry| OrderBookEntry.new(entry) }
      end

      attr_reader :asks, :bids

      def best_ask
        @asks.first
      end

      def best_bid
        @bids.first
      end

      def spread
        return nil unless best_ask && best_bid
        
        best_ask.price - best_bid.price
      end

      def spread_percentage
        return nil unless best_ask && best_bid && best_bid.price > 0
        
        ((best_ask.price - best_bid.price) / best_bid.price * 100).round(4)
      end
    end

    # Trade model
    class Trade < BaseModel
      def initialize(data)
        super(data)
        @timestamp = parse_datetime(data["timestamp"]) || Time.at(data["timestamp"].to_i) if data["timestamp"]
        @direction = data["direction"]
        @price = parse_amount(data["price"])
        @amount = parse_amount(data["amount"])
        @market_id = data["market_id"]
      end

      attr_reader :timestamp, :direction, :price, :amount, :market_id
    end

    # Trades collection model
    class Trades < BaseModel
      def initialize(data)
        super(data) 
        @trades = (data["trades"] || []).map { |trade_data| Trade.new(trade_data) }
        @last_timestamp = data["last_timestamp"]
      end

      attr_reader :trades, :last_timestamp

      def count
        @trades.length
      end

      def each(&block)
        @trades.each(&block)
      end
    end

    # Balance model
    class Balance < BaseModel
      def initialize(data)
        super(data)
        @id = data["id"] 
        @account_id = data["account_id"]
        @amount = parse_amount(data["amount"])
        @available_amount = parse_amount(data["available_amount"])
        @frozen_amount = parse_amount(data["frozen_amount"])
        @pending_withdraw_amount = parse_amount(data["pending_withdraw_amount"])
      end

      attr_reader :id, :account_id, :amount, :available_amount, 
                  :frozen_amount, :pending_withdraw_amount

      def currency
        @amount&.currency
      end
    end

    # Order model
    class Order < BaseModel
      def initialize(data)
        super(data)
        @id = data["id"]
        @account_id = data["account_id"]
        @amount = parse_amount(data["amount"])
        @created_at = parse_datetime(data["created_at"])
        @fee_currency = data["fee_currency"]
        @limit = parse_amount(data["limit"])
        @market_id = data["market_id"]
        @original_amount = parse_amount(data["original_amount"])
        @paid_fee = parse_amount(data["paid_fee"])
        @price_type = data["price_type"]
        @state = data["state"]
        @total_exchanged = parse_amount(data["total_exchanged"])
        @traded_amount = parse_amount(data["traded_amount"])
        @type = data["type"]
      end

      attr_reader :id, :account_id, :amount, :created_at, :fee_currency,
                  :limit, :market_id, :original_amount, :paid_fee, :price_type,
                  :state, :total_exchanged, :traded_amount, :type

      def filled_percentage
        return 0 unless @original_amount&.amount && @original_amount.amount > 0
        
        ((@traded_amount&.amount || 0) / @original_amount.amount * 100).round(2)
      end

      def is_filled?
        @state == "traded"
      end

      def is_active?
        %w[received pending].include?(@state)
      end

      def is_cancelled?
        %w[canceled canceling].include?(@state)
      end
    end

    # Quotation model  
    class Quotation < BaseModel
      def initialize(data)
        super(data)
        @type = data["type"]
        @reverse_amount = parse_amount(data["reverse_amount"])
        @amount = parse_amount(data["amount"])
        @base_balance_change = parse_amount(data["base_balance_change"])
        @quote_balance_change = parse_amount(data["quote_balance_change"])
        @fee = parse_amount(data["fee"])
      end

      attr_reader :type, :reverse_amount, :amount, :base_balance_change,
                  :quote_balance_change, :fee
    end

    # Withdrawal model
    class Withdrawal < BaseModel
      def initialize(data)
        super(data)
        @id = data["id"]
        @created_at = parse_datetime(data["created_at"])
        @amount = parse_amount(data["amount"])
        @fee = parse_amount(data["fee"])
        @currency = data["currency"]
        @state = data["state"]
        @withdrawal_data = data["withdrawal_data"]
      end

      attr_reader :id, :created_at, :amount, :fee, :currency, :state, :withdrawal_data

      def target_address
        @withdrawal_data&.dig("target_address")
      end
    end

    # Deposit model  
    class Deposit < BaseModel
      def initialize(data)
        super(data)
        @id = data["id"]
        @created_at = parse_datetime(data["created_at"])
        @amount = parse_amount(data["amount"])
        @currency = data["currency"]
        @state = data["state"]
        @deposit_data = data["deposit_data"]
      end

      attr_reader :id, :created_at, :amount, :currency, :state, :deposit_data

      def address
        @deposit_data&.dig("address")
      end
    end

    # Pagination metadata
    class PaginationMeta < BaseModel
      def initialize(data)
        super(data)
        @current_page = data["current_page"]&.to_i
        @total_count = data["total_count"]&.to_i
        @total_pages = data["total_pages"]&.to_i
      end

      attr_reader :current_page, :total_count, :total_pages

      def has_next_page?
        @current_page && @total_pages && @current_page < @total_pages
      end

      def has_previous_page?
        @current_page && @current_page > 1
      end
    end

    # Paginated collection of orders
    class OrderPages < BaseModel
      def initialize(orders_data, meta_data)
        @orders = orders_data.map { |order| Order.new(order) }
        @meta = PaginationMeta.new(meta_data || {})
      end

      attr_reader :orders, :meta

      def count
        @orders.length
      end

      def each(&block)
        @orders.each(&block)
      end
    end

    # Average price report entry
    class AveragePrice < BaseModel
      def initialize(data)
        super(data)
        @timestamp = Time.at(data["timestamp"].to_i) if data["timestamp"]
        @average = data["average"]&.to_f
      end

      attr_reader :timestamp, :average
    end

    # Candlestick report entry  
    class Candlestick < BaseModel
      def initialize(data)
        super(data)
        @timestamp = Time.at(data["timestamp"].to_i) if data["timestamp"]
        @open = data["open"]&.to_f
        @close = data["close"]&.to_f
        @high = data["high"]&.to_f  
        @low = data["low"]&.to_f
        @volume = data["volume"]&.to_f
      end

      attr_reader :timestamp, :open, :close, :high, :low, :volume
    end
  end
end