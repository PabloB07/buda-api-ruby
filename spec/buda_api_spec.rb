# Example RSpec test file
# This demonstrates how to test the SDK

require 'spec_helper'

RSpec.describe BudaApi::PublicClient do
  let(:client) { BudaApi::PublicClient.new }

  describe '#markets' do
    it 'returns an array of markets', :vcr do
      markets = client.markets
      
      expect(markets).to be_an(Array)
      expect(markets).not_to be_empty
      expect(markets.first).to be_a(BudaApi::Models::Market)
    end
  end

  describe '#ticker' do
    it 'returns ticker information for a valid market', :vcr do
      ticker = client.ticker('BTC-CLP')
      
      expect(ticker).to be_a(BudaApi::Models::Ticker)
      expect(ticker.last_price).to be_a(BudaApi::Models::Amount)
      expect(ticker.last_price.currency).to eq('CLP')
    end

    it 'raises ValidationError for invalid market' do
      expect {
        client.ticker('INVALID-MARKET')
      }.to raise_error(BudaApi::ValidationError)
    end
  end

  describe '#order_book' do
    it 'returns order book for a valid market', :vcr do
      order_book = client.order_book('BTC-CLP')
      
      expect(order_book).to be_a(BudaApi::Models::OrderBook)
      expect(order_book.asks).to be_an(Array)
      expect(order_book.bids).to be_an(Array)
      expect(order_book.best_ask).to be_a(BudaApi::Models::OrderBookEntry)
      expect(order_book.best_bid).to be_a(BudaApi::Models::OrderBookEntry)
    end
  end
end

RSpec.describe BudaApi::AuthenticatedClient do
  let(:client) do
    BudaApi::AuthenticatedClient.new(
      api_key: 'test_key',
      api_secret: 'test_secret'
    )
  end

  describe '#initialize' do
    it 'requires api_key and api_secret' do
      expect {
        BudaApi::AuthenticatedClient.new(api_key: '', api_secret: 'secret')
      }.to raise_error(BudaApi::ConfigurationError)

      expect {
        BudaApi::AuthenticatedClient.new(api_key: 'key', api_secret: '')
      }.to raise_error(BudaApi::ConfigurationError)
    end
  end

  describe '#balance' do
    it 'validates currency parameter' do
      expect {
        client.balance('INVALID')
      }.to raise_error(BudaApi::ValidationError)
    end
  end
end