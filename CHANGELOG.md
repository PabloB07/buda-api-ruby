# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-07

### Added
- Initial release of Buda API Ruby SDK
- Complete public API coverage:
  - Market data (markets, tickers, order books, trades)
  - Quotations and price calculations
  - Historical reports (average prices, candlesticks)
- Complete authenticated API coverage:
  - Account balances and balance events
  - Order management (place, cancel, batch operations)
  - Transfer management (deposits, withdrawals)
  - Order history and pagination
- Comprehensive error handling with specific exception classes
- Debug logging with detailed HTTP request/response information
- Automatic retry logic with exponential backoff
- HMAC-SHA384 authentication with automatic signature generation
- Rich data models with helper methods and type safety
- Extensive documentation and examples
- Trading bot example with price monitoring
- Configuration management system
- Rate limiting handling

### Security
- Secure HMAC authentication implementation
- Proper API key validation
- Safe parameter handling and validation

### Documentation
- Complete API reference documentation
- Comprehensive README with examples
- Inline code documentation
- Multiple usage examples including:
  - Public API usage
  - Authenticated API usage  
  - Error handling and debugging
  - Advanced trading bot implementation

## [Unreleased]

### Planned
- WebSocket API support for real-time data
- Advanced order types support
- Portfolio management utilities
- Performance optimizations
- Additional trading strategy examples