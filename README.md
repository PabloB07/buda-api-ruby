# Unofficial Buda API Ruby SDK

A comprehensive Ruby SDK for [Buda.com](https://buda.com) cryptocurrency exchange API with built-in debugging, error handling, and extensive examples.

[![Ruby](https://img.shields.io/badge/Ruby-2.7%2B-red)](https://ruby-lang.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/Documentation-YARD-blue)](https://rubydoc.info/)

## Features

- ✅ **Complete API Coverage** - All public and authenticated endpoints
- 🛡️ **Robust Error Handling** - Comprehensive exception handling with detailed error context
- 🔍 **Debug Mode** - Detailed HTTP request/response logging for development
- 📊 **Rich Data Models** - Object-oriented response models with helper methods  
- 🔐 **Secure Authentication** - HMAC-SHA384 authentication with automatic signature generation
- ⚡ **Automatic Retries** - Built-in retry logic for transient failures
- 📖 **Extensive Documentation** - Complete API reference and examples
- 🧪 **Comprehensive Examples** - Real-world usage examples including a trading bot

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'buda_api'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install buda_api
```

## Quick Start

### Public API (No Authentication Required)

```ruby
require 'buda_api'

# Create a public client
client = BudaApi.public_client

# Get all markets
markets = client.markets
puts "Available markets: #{markets.map(&:id).join(', ')}"

# Get ticker information
ticker = client.ticker("BTC-CLP")
puts "BTC-CLP price: #{ticker.last_price}"
puts "24h change: #{ticker.price_variation_24h}%"

# Get order book
order_book = client.order_book("BTC-CLP")
puts "Best ask: #{order_book.best_ask.price}"
puts "Best bid: #{order_book.best_bid.price}"
puts "Spread: #{order_book.spread_percentage}%"
```

### Authenticated API (Trading)

```ruby
require 'buda_api'

# Create authenticated client
client = BudaApi.authenticated_client(
  api_key: "your_api_key",
  api_secret: "your_api_secret"
)

# Check your balance
balance = client.balance("BTC")
puts "Available BTC: #{balance.available_amount}"

# Place a limit buy order
order = client.place_order("BTC-CLP", "Bid", "limit", 0.001, 50000000)
puts "Order placed: #{order.id}"

# Cancel the order
cancelled = client.cancel_order(order.id)
puts "Order cancelled: #{cancelled.state}"
```

## Configuration

Configure the SDK globally:

```ruby
BudaApi.configure do |config|
  config.debug_mode = true           # Enable debug logging
  config.timeout = 30               # Request timeout in seconds  
  config.retries = 3                # Number of retry attempts
  config.logger_level = :info       # Logging level
  config.base_url = "https://www.buda.com/api/v2/"  # API base URL
end
```

## API Reference

### Public API Methods

#### Markets

```ruby
# Get all available markets
markets = client.markets
# Returns: Array<BudaApi::Models::Market>

# Get specific market details  
market = client.market_details("BTC-CLP")
# Returns: BudaApi::Models::Market
```

#### Market Data

```ruby
# Get ticker information
ticker = client.ticker("BTC-CLP")
# Returns: BudaApi::Models::Ticker

# Get order book
order_book = client.order_book("BTC-CLP")  
# Returns: BudaApi::Models::OrderBook

# Get recent trades
trades = client.trades("BTC-CLP", limit: 50)
# Returns: BudaApi::Models::Trades
```

#### Quotations

```ruby
# Get price quotation for buying 0.1 BTC at market price
quote = client.quotation("BTC-CLP", "bid_given_size", 0.1)
# Returns: BudaApi::Models::Quotation

# Get price quotation with limit price
quote = client.quotation_limit("BTC-CLP", "ask_given_size", 0.1, 60000000)
# Returns: BudaApi::Models::Quotation
```

#### Reports

```ruby
# Get average price report
start_time = Time.now - 86400  # 24 hours ago
avg_prices = client.average_prices_report("BTC-CLP", start_at: start_time)
# Returns: Array<BudaApi::Models::AveragePrice>

# Get candlestick data
candles = client.candlestick_report("BTC-CLP", start_at: start_time)
# Returns: Array<BudaApi::Models::Candlestick>
```

### Authenticated API Methods

#### Account Information

```ruby
# Get balance for specific currency
balance = client.balance("BTC")
# Returns: BudaApi::Models::Balance

# Get balance events with filtering
events = client.balance_events(
  currencies: ["BTC", "CLP"],
  event_names: ["deposit_confirm", "withdrawal_confirm"],
  page: 1,
  per_page: 50
)
# Returns: Hash with :events and :total_count
```

#### Trading

```ruby
# Place orders
buy_order = client.place_order("BTC-CLP", "Bid", "limit", 0.001, 50000000)
sell_order = client.place_order("BTC-CLP", "Ask", "market", 0.001)

# Get order history
orders = client.orders("BTC-CLP", page: 1, per_page: 100, state: "traded")
# Returns: BudaApi::Models::OrderPages

# Get specific order details
order = client.order_details(12345)
# Returns: BudaApi::Models::Order

# Cancel order
cancelled = client.cancel_order(12345)
# Returns: BudaApi::Models::Order

# Batch operations (cancel multiple, place multiple)
result = client.batch_orders(
  cancel_orders: [123, 456],
  place_orders: [
    { type: "Bid", price_type: "limit", amount: "0.001", limit: "50000" }
  ]
)
```

#### Transfers

```ruby
# Get withdrawals
withdrawals = client.withdrawals("BTC", page: 1, per_page: 20)
# Returns: Hash with :withdrawals and :meta

# Get deposits  
deposits = client.deposits("BTC", page: 1, per_page: 20)
# Returns: Hash with :deposits and :meta

# Simulate withdrawal (calculate fees without executing)
simulation = client.simulate_withdrawal("BTC", 0.01)
# Returns: BudaApi::Models::Withdrawal

# Execute withdrawal
withdrawal = client.withdrawal("BTC", 0.01, "destination_address")
# Returns: BudaApi::Models::Withdrawal
```

## Error Handling

The SDK provides comprehensive error handling with specific exception classes:

```ruby
begin
  ticker = client.ticker("INVALID-MARKET")
rescue BudaApi::ValidationError => e
  puts "Validation failed: #{e.message}"
rescue BudaApi::NotFoundError => e
  puts "Resource not found: #{e.message}"
rescue BudaApi::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue BudaApi::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue BudaApi::ServerError => e
  puts "Server error: #{e.message}"
rescue BudaApi::ConnectionError => e
  puts "Connection failed: #{e.message}"
rescue BudaApi::ApiError => e
  puts "API error: #{e.message}"
  puts "Status: #{e.status_code}"
  puts "Response: #{e.response_body}"
end
```

### Exception Hierarchy

```
BudaApi::ApiError (base class)
├── BudaApi::AuthenticationError    # 401 errors
├── BudaApi::AuthorizationError     # 403 errors  
├── BudaApi::BadRequestError        # 400 errors
├── BudaApi::NotFoundError          # 404 errors
├── BudaApi::RateLimitError         # 429 errors
├── BudaApi::ServerError            # 5xx errors
├── BudaApi::ConnectionError        # Network issues
├── BudaApi::TimeoutError           # Request timeouts
└── BudaApi::InvalidResponseError   # Invalid response format

BudaApi::ValidationError            # Parameter validation
BudaApi::ConfigurationError         # SDK configuration issues
```

## Debugging

Enable debug mode to see detailed HTTP request/response logs:

```ruby
BudaApi.configure do |config|
  config.debug_mode = true
  config.logger_level = :debug
end

# All requests will now show detailed logs:
# → GET https://www.buda.com/api/v2/markets/BTC-CLP/ticker
# → Headers: {"User-Agent"=>"BudaApi Ruby SDK 1.0.0"}  
# ← 200
# ← Headers: {"content-type"=>"application/json"}
# ← Body: {"ticker": {...}}
# ← Duration: 150ms
```

## Data Models

All API responses are wrapped in rich data model objects with helper methods:

### Market Model

```ruby
market = client.market_details("BTC-CLP")

market.id                    # => "BTC-CLP"
market.name                  # => "Bitcoin/Chilean Peso"  
market.base_currency         # => "BTC"
market.quote_currency        # => "CLP"
market.minimum_order_amount  # => #<BudaApi::Models::Amount>
```

### Ticker Model

```ruby
ticker = client.ticker("BTC-CLP")

ticker.last_price           # => #<BudaApi::Models::Amount>
ticker.min_ask             # => #<BudaApi::Models::Amount>
ticker.max_bid             # => #<BudaApi::Models::Amount>  
ticker.volume              # => #<BudaApi::Models::Amount>
ticker.price_variation_24h # => -2.5 (percentage)
ticker.price_variation_7d  # => 10.3 (percentage)
```

### OrderBook Model

```ruby
order_book = client.order_book("BTC-CLP")

order_book.asks           # => Array<BudaApi::Models::OrderBookEntry>
order_book.bids           # => Array<BudaApi::Models::OrderBookEntry>
order_book.best_ask       # => #<BudaApi::Models::OrderBookEntry>
order_book.best_bid       # => #<BudaApi::Models::OrderBookEntry>
order_book.spread         # => 50000.0 (price difference)
order_book.spread_percentage # => 0.12 (percentage)
```

### Order Model

```ruby
order = client.order_details(12345)

order.id                  # => 12345
order.state               # => "traded" 
order.type                # => "Bid"
order.amount              # => #<BudaApi::Models::Amount>
order.limit               # => #<BudaApi::Models::Amount>
order.traded_amount       # => #<BudaApi::Models::Amount>
order.filled_percentage   # => 100.0
order.is_filled?          # => true
order.is_active?          # => false
order.is_cancelled?       # => false
```

### Balance Model

```ruby
balance = client.balance("BTC")

balance.currency                # => "BTC"
balance.amount                  # => #<BudaApi::Models::Amount> (total)
balance.available_amount        # => #<BudaApi::Models::Amount>
balance.frozen_amount           # => #<BudaApi::Models::Amount> 
balance.pending_withdraw_amount # => #<BudaApi::Models::Amount>
```

## Examples

The SDK includes comprehensive examples in the `examples/` directory:

### Basic Examples

- [`public_api_example.rb`](examples/public_api_example.rb) - Public API usage
- [`authenticated_api_example.rb`](examples/authenticated_api_example.rb) - Authenticated API usage  
- [`error_handling_example.rb`](examples/error_handling_example.rb) - Error handling and debugging

### Advanced Examples

- [`trading_bot_example.rb`](examples/trading_bot_example.rb) - Simple trading bot with price monitoring

### Running Examples

1. Copy the environment file:
```bash
cp examples/.env.example examples/.env
```

2. Edit `.env` and add your API credentials:
```bash
BUDA_API_KEY=your_api_key_here
BUDA_API_SECRET=your_api_secret_here
```

3. Run the examples:
```bash
# Public API example (no credentials needed)
ruby examples/public_api_example.rb

# Authenticated API example (requires credentials)
ruby examples/authenticated_api_example.rb

# Error handling example
ruby examples/error_handling_example.rb

# Trading bot example (requires credentials)
ruby examples/trading_bot_example.rb BTC-CLP
```

## Constants

The SDK provides convenient constants for all supported values:

```ruby
# Currencies
BudaApi::Constants::Currency::BTC     # => "BTC"
BudaApi::Constants::Currency::ALL     # => ["BTC", "ETH", "CLP", ...]

# Markets  
BudaApi::Constants::Market::BTC_CLP   # => "BTC-CLP"
BudaApi::Constants::Market::ALL       # => ["BTC-CLP", "ETH-CLP", ...]

# Order types
BudaApi::Constants::OrderType::BID    # => "Bid" (buy)
BudaApi::Constants::OrderType::ASK    # => "Ask" (sell)

# Price types
BudaApi::Constants::PriceType::MARKET # => "market"
BudaApi::Constants::PriceType::LIMIT  # => "limit"

# Order states
BudaApi::Constants::OrderState::PENDING   # => "pending"
BudaApi::Constants::OrderState::TRADED    # => "traded"
BudaApi::Constants::OrderState::CANCELED  # => "canceled"
```

## Rate Limiting

The SDK automatically handles rate limiting with exponential backoff retry logic. When rate limits are hit:

1. The request is automatically retried after a delay
2. The delay increases exponentially for subsequent retries  
3. After maximum retries, a `RateLimitError` is raised

You can configure retry behavior:

```ruby
BudaApi.configure do |config|
  config.retries = 5           # Maximum retry attempts
  config.timeout = 60          # Request timeout
end
```

## Security

### API Key Security

- Never commit API keys to version control
- Use environment variables or secure configuration management
- Rotate API keys regularly
- Use API keys with minimal required permissions

### HMAC Authentication

The SDK automatically handles HMAC-SHA384 signature generation:

1. Generates a unique nonce for each request
2. Creates signature using HTTP method, path, body, and nonce
3. Includes proper headers: `X-SBTC-APIKEY`, `X-SBTC-NONCE`, `X-SBTC-SIGNATURE`

## Contributing

1. Fork it (https://github.com/yourusername/buda-api-ruby/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Development Setup

```bash
git clone https://github.com/yourusername/buda-api-ruby.git
cd buda-api-ruby
bundle install
bundle exec rspec
```

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec --format documentation

# Run specific test file
bundle exec rspec spec/client_spec.rb
```

## Changelog

### Version 1.0.0

- Initial release
- Complete public and authenticated API coverage
- Comprehensive error handling
- Debug logging and monitoring
- Rich data models with helper methods
- Automatic retries and rate limit handling
- Extensive documentation and examples

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Disclaimer

This SDK is provided "as is" without warranty. Trading cryptocurrencies involves substantial risk of loss. Always test thoroughly in a staging environment before using in production. Never risk more than you can afford to lose.

The authors and contributors are not responsible for any financial losses incurred through the use of this SDK.

## Support

- 📖 [API Documentation](https://api.buda.com)  
- 🐛 [Issue Tracker](https://github.com/yourusername/buda-api-ruby/issues)
- 💬 [Discussions](https://github.com/yourusername/buda-api-ruby/discussions)

## Related Projects

- [Buda Python SDK](https://github.com/delta575/trading-api-wrappers) - Official Python wrapper
- [Buda API Documentation](https://api.buda.com) - Official API docs