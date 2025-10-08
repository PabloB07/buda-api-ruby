# frozen_string_literal: true

module BudaApi
  # Constants and enums for the Buda API
  module Constants
    # Supported currencies
    module Currency
      ARS = "ARS"    # Argentine Peso
      BCH = "BCH"    # Bitcoin Cash
      BTC = "BTC"    # Bitcoin
      CLP = "CLP"    # Chilean Peso  
      COP = "COP"    # Colombian Peso
      ETH = "ETH"    # Ethereum
      LTC = "LTC"    # Litecoin
      PEN = "PEN"    # Peruvian Sol
      USDC = "USDC"  # USD Coin

      ALL = [ARS, BCH, BTC, CLP, COP, ETH, LTC, PEN, USDC].freeze

      # Currency decimal places
      DECIMALS = {
        ARS => 2,
        BCH => 8,
        BTC => 8,
        CLP => 2,
        COP => 2,
        ETH => 9,
        LTC => 8,
        PEN => 2,
        USDC => 2
      }.freeze
    end

    # Supported trading pairs
    module Market
      # Bitcoin pairs
      BTC_ARS = "BTC-ARS"
      BTC_CLP = "BTC-CLP"
      BTC_COP = "BTC-COP"
      BTC_PEN = "BTC-PEN"
      BTC_USDC = "BTC-USDC"

      # Ethereum pairs
      ETH_ARS = "ETH-ARS"
      ETH_BTC = "ETH-BTC"
      ETH_CLP = "ETH-CLP" 
      ETH_COP = "ETH-COP"
      ETH_PEN = "ETH-PEN"

      # Bitcoin Cash pairs
      BCH_ARS = "BCH-ARS"
      BCH_BTC = "BCH-BTC"
      BCH_CLP = "BCH-CLP"
      BCH_COP = "BCH-COP"
      BCH_PEN = "BCH-PEN"

      # Litecoin pairs
      LTC_ARS = "LTC-ARS"
      LTC_BTC = "LTC-BTC"
      LTC_CLP = "LTC-CLP"
      LTC_COP = "LTC-COP"
      LTC_PEN = "LTC-PEN"

      # USDC pairs
      USDC_ARS = "USDC-ARS"
      USDC_CLP = "USDC-CLP"
      USDC_COP = "USDC-COP"
      USDC_PEN = "USDC-PEN"

      ALL = [
        BTC_ARS, BTC_CLP, BTC_COP, BTC_PEN, BTC_USDC,
        ETH_ARS, ETH_BTC, ETH_CLP, ETH_COP, ETH_PEN,
        BCH_ARS, BCH_BTC, BCH_CLP, BCH_COP, BCH_PEN,
        LTC_ARS, LTC_BTC, LTC_CLP, LTC_COP, LTC_PEN,
        USDC_ARS, USDC_CLP, USDC_COP, USDC_PEN
      ].freeze
    end

    # Order types
    module OrderType
      ASK = "Ask"    # Sell order
      BID = "Bid"    # Buy order

      ALL = [ASK, BID].freeze
    end

    # Price types for orders
    module PriceType
      MARKET = "market"
      LIMIT = "limit"

      ALL = [MARKET, LIMIT].freeze
    end

    # Order states
    module OrderState
      RECEIVED = "received"
      PENDING = "pending"
      TRADED = "traded"
      CANCELING = "canceling"
      CANCELED = "canceled"

      ALL = [RECEIVED, PENDING, TRADED, CANCELING, CANCELED].freeze
    end

    # Quotation types
    module QuotationType
      BID_GIVEN_SIZE = "bid_given_size"
      BID_GIVEN_EARNED_BASE = "bid_given_earned_base"
      BID_GIVEN_SPENT_QUOTE = "bid_given_spent_quote"
      ASK_GIVEN_SIZE = "ask_given_size"
      ASK_GIVEN_EARNED_QUOTE = "ask_given_earned_quote"
      ASK_GIVEN_SPENT_BASE = "ask_given_spent_base"

      ALL = [
        BID_GIVEN_SIZE, BID_GIVEN_EARNED_BASE, BID_GIVEN_SPENT_QUOTE,
        ASK_GIVEN_SIZE, ASK_GIVEN_EARNED_QUOTE, ASK_GIVEN_SPENT_BASE
      ].freeze
    end

    # Balance event types
    module BalanceEvent
      DEPOSIT_CONFIRM = "deposit_confirm"
      WITHDRAWAL_CONFIRM = "withdrawal_confirm" 
      TRANSACTION = "transaction"
      TRANSFER_CONFIRMATION = "transfer_confirmation"

      ALL = [DEPOSIT_CONFIRM, WITHDRAWAL_CONFIRM, TRANSACTION, TRANSFER_CONFIRMATION].freeze
    end

    # Report types
    module ReportType
      AVERAGE_PRICES = "average_prices"
      CANDLESTICK = "candlestick"

      ALL = [AVERAGE_PRICES, CANDLESTICK].freeze
    end

    # API limits
    module Limits
      ORDERS_PER_PAGE = 300
      TRANSFERS_PER_PAGE = 300
      DEFAULT_TIMEOUT = 30
      MAX_RETRIES = 3
    end

    # HTTP status codes
    module HttpStatus
      OK = 200
      CREATED = 201
      BAD_REQUEST = 400
      UNAUTHORIZED = 401
      FORBIDDEN = 403
      NOT_FOUND = 404
      UNPROCESSABLE_ENTITY = 422
      RATE_LIMITED = 429
      INTERNAL_SERVER_ERROR = 500
      BAD_GATEWAY = 502
      SERVICE_UNAVAILABLE = 503
      GATEWAY_TIMEOUT = 504
    end
  end
end