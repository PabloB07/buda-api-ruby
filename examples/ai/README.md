# AI-Enhanced Ruby SDK Examples

This directory contains comprehensive examples demonstrating the AI-powered features of the BudaApi Ruby SDK.

## Examples Overview

### 1. Trading Assistant (`trading_assistant_example.rb`)
**Main AI-Enhanced Trading Example**

Comprehensive demonstration of AI trading capabilities including:
- **Market Analysis**: AI-powered technical and fundamental analysis
- **Trading Strategies**: Intelligent strategy recommendations
- **Entry/Exit Signals**: Automated signal generation
- **Natural Language Trading**: Conversational trading interface
- **Risk Management**: Portfolio risk assessment
- **Anomaly Detection**: Market irregularity detection
- **Report Generation**: AI-generated trading reports
- **Interactive Mode**: Real-time AI trading assistant

```bash
# Run the main example
ruby examples/ai/trading_assistant_example.rb

# Run in interactive mode
ruby examples/ai/trading_assistant_example.rb
# Select option 2 for interactive mode
```

### 2. Advanced Risk Management (`risk_management_example.rb`)
**Comprehensive Risk Analysis System**

Features:
- **Portfolio Risk Analysis**: Diversification and concentration analysis
- **Pre-Trade Risk Evaluation**: Risk assessment before placing orders
- **Risk Monitoring**: Real-time threshold monitoring with alerts
- **Stop-Loss Recommendations**: AI-calculated stop-loss levels
- **Position Sizing**: Risk-adjusted position calculations
- **Correlation Analysis**: Asset correlation detection
- **Risk Dashboard**: Comprehensive risk overview

```bash
ruby examples/ai/risk_management_example.rb
```

### 3. Natural Language Trading (`natural_language_trading.rb`)
**Conversational Trading Interface**

Chat-based trading with AI:
- **Natural Language Queries**: Ask questions in plain English
- **Balance Inquiries**: "Check my BTC balance"
- **Market Data**: "What's the current price of Ethereum?"
- **Trading Commands**: "Buy 0.001 BTC at market price"
- **Safety Features**: Demo mode and confirmations
- **Context Awareness**: Maintains conversation history

```bash
ruby examples/ai/natural_language_trading.rb
```

### 4. Anomaly Detection (`anomaly_detection_example.rb`)
**AI-Powered Market Monitoring**

Automated market surveillance:
- **Real-Time Scanning**: Continuous market anomaly detection
- **Multiple Detection Types**: Price spikes, volume anomalies, whale activity
- **Severity Classification**: Critical, high, medium, low alerts
- **Historical Analysis**: Pattern detection in historical data
- **AI Analysis**: Intelligent anomaly interpretation
- **Monitoring Modes**: One-time, continuous, or single-market analysis

```bash
# One-time scan
ruby examples/ai/anomaly_detection_example.rb

# Demo mode (simulated data)
ruby examples/ai/anomaly_detection_example.rb --demo
```

### 5. Report Generation (`report_generation_example.rb`)
**Automated AI Report System**

Professional trading reports:
- **Portfolio Reports**: Comprehensive portfolio analysis
- **Trading Performance**: Trading statistics and insights
- **Market Analysis**: Market trend analysis
- **Custom Reports**: AI-generated custom analysis
- **Multiple Formats**: Markdown, HTML, JSON, CSV export
- **Report Dashboard**: Interactive report generation interface

```bash
# Interactive dashboard
ruby examples/ai/report_generation_example.rb

# Generate demo reports
ruby examples/ai/report_generation_example.rb --demo
```

## Prerequisites

### Required Gems
```bash
# Install the AI dependency
gem install ruby_llm

# Or add to your Gemfile
gem 'ruby_llm', '~> 0.5'
```

### API Configuration
Set your Buda API credentials:

```bash
export BUDA_API_KEY="your_api_key_here"
export BUDA_API_SECRET="your_api_secret_here"
```

### LLM Provider Setup
Configure your preferred AI provider:

**OpenAI (Recommended)**
```bash
export OPENAI_API_KEY="your_openai_key"
```

**Anthropic Claude**
```bash
export ANTHROPIC_API_KEY="your_anthropic_key"
```

## Usage Patterns

### Basic AI Trading Assistant
```ruby
require_relative '../lib/buda_api'

client = BudaApi::AuthenticatedClient.new(
  api_key: ENV['BUDA_API_KEY'],
  api_secret: ENV['BUDA_API_SECRET']
)

# Initialize AI assistant
assistant = BudaApi.trading_assistant(client)

# Get market analysis
analysis = assistant.analyze_market("BTC-CLP")
puts "Trend: #{analysis[:trend]}"
puts "AI Recommendation: #{analysis[:ai_recommendation][:action]}"
```

### Natural Language Trading
```ruby
# Create natural language trader
nl_trader = BudaApi.natural_language_trader(client)

# Execute commands in natural language
result = nl_trader.execute_command("Check my Bitcoin balance")
result = nl_trader.execute_command("What's the current ETH price?")
result = nl_trader.execute_command("Buy 0.001 BTC at market price")
```

### Risk Management
```ruby
# Initialize risk manager
risk_manager = BudaApi::AI::RiskManager.new(client)

# Analyze portfolio risk
portfolio_risk = risk_manager.analyze_portfolio_risk(
  include_ai_insights: true
)

# Evaluate trade risk
trade_risk = risk_manager.evaluate_trade_risk(
  "BTC-CLP", "buy", 0.001
)

puts "Trade Risk: #{trade_risk[:risk_level]}"
puts "Should Proceed: #{trade_risk[:should_proceed]}"
```

### Anomaly Detection
```ruby
# Create anomaly detector
detector = BudaApi::AI::AnomalyDetector.new(client)

# Detect market anomalies
anomalies = detector.detect_market_anomalies(
  markets: ["BTC-CLP", "ETH-CLP"],
  include_ai_analysis: true
)

puts "Anomalies Detected: #{anomalies[:anomalies_detected]}"
```

### Report Generation
```ruby
# Initialize report generator
reporter = BudaApi::AI::ReportGenerator.new(client)

# Generate portfolio report
report = reporter.generate_portfolio_summary(
  format: "markdown",
  include_ai: true
)

# Export to file
reporter.export_report(report, "portfolio_report.md")
```

## AI Features Overview

### Market Analysis Capabilities
- **Technical Analysis**: Price patterns, trends, support/resistance
- **Fundamental Analysis**: Market sentiment, news impact assessment
- **Risk Assessment**: Volatility analysis, correlation detection
- **Strategy Recommendations**: Entry/exit points, position sizing

### Natural Language Processing
- **Command Interpretation**: Understands trading intentions in natural language
- **Context Awareness**: Maintains conversation history and context
- **Error Handling**: Provides helpful suggestions for unclear commands
- **Safety Features**: Confirms potentially risky operations

### Risk Management AI
- **Portfolio Analysis**: Diversification scoring, concentration risk
- **Pre-Trade Evaluation**: Impact assessment before order placement
- **Dynamic Monitoring**: Real-time risk threshold monitoring
- **Predictive Modeling**: Risk-adjusted return optimization

### Anomaly Detection AI
- **Pattern Recognition**: Identifies unusual market behaviors
- **Multi-Factor Analysis**: Price, volume, spread, and correlation anomalies
- **Severity Scoring**: Intelligent risk prioritization
- **Real-Time Monitoring**: Continuous market surveillance

### Report Generation AI
- **Intelligent Summarization**: Key insights extraction
- **Trend Analysis**: Pattern identification and explanation
- **Actionable Recommendations**: Specific improvement suggestions
- **Multi-Format Export**: Professional report formatting

## Safety Features

### Demo Mode
All examples default to demo/sandbox mode for safety:
- No real trades are executed without explicit confirmation
- Clear indicators when in demo vs. live mode
- Sandbox API endpoints used by default

### Confirmation Systems
- **Trade Confirmations**: All trading operations require explicit confirmation
- **Risk Warnings**: High-risk operations trigger warnings
- **Clear Feedback**: Detailed success/error messages

### Error Handling
- **Graceful Degradation**: Functions work even if AI features unavailable
- **Helpful Error Messages**: Clear guidance when issues occur
- **Fallback Options**: Alternative approaches when AI fails

## Performance Notes

### API Rate Limits
- Examples include appropriate delays between API calls
- Batch operations optimize API usage
- Rate limit error handling and retry logic

### AI Provider Costs
- Most examples use moderate token limits to control costs
- Optional AI features can be disabled to reduce usage
- Clear documentation of approximate token consumption

## Troubleshooting

### Common Issues

**AI Features Not Available**
```
❌ AI features are not available. Please install ruby_llm gem:
   gem install ruby_llm
```

**Authentication Errors**
```
❌ Authentication failed. Please check your API credentials.
```
Set proper environment variables:
```bash
export BUDA_API_KEY="your_key"
export BUDA_API_SECRET="your_secret"
```

**LLM API Errors**
- Verify your LLM provider API key is set
- Check your API quota/billing status
- Try a different LLM provider

### Debug Mode
Enable debug output:
```bash
DEBUG=1 ruby examples/ai/trading_assistant_example.rb
```

## Contributing

When adding new AI examples:

1. **Follow Safety Patterns**: Always default to demo mode
2. **Include Error Handling**: Graceful degradation when AI unavailable
3. **Add Documentation**: Clear comments and usage instructions
4. **Test Thoroughly**: Verify both AI and non-AI code paths
5. **Optimize Costs**: Be mindful of LLM API usage

## License

These examples are part of the BudaApi Ruby SDK and are subject to the same license terms.