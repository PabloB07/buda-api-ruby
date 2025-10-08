# frozen_string_literal: true

module BudaApi
  # Custom error classes for the Buda API SDK
  module Errors
    # Base error class for all API errors
    class ApiError < StandardError
      attr_reader :status_code, :response_body, :response_headers

      def initialize(message, status_code: nil, response_body: nil, response_headers: nil)
        super(message)
        @status_code = status_code
        @response_body = response_body
        @response_headers = response_headers
      end

      def to_s
        msg = super
        msg += " (HTTP #{@status_code})" if @status_code
        msg
      end
    end

    # Authentication related errors
    class AuthenticationError < ApiError; end

    # Authorization/permission related errors  
    class AuthorizationError < ApiError; end

    # Rate limiting errors
    class RateLimitError < ApiError; end

    # Invalid request errors (4xx)
    class BadRequestError < ApiError; end

    # Resource not found errors
    class NotFoundError < ApiError; end

    # Server errors (5xx)
    class ServerError < ApiError; end

    # Network/connection related errors
    class ConnectionError < ApiError; end

    # Request timeout errors
    class TimeoutError < ApiError; end

    # Invalid response format errors
    class InvalidResponseError < ApiError; end

    # Configuration errors
    class ConfigurationError < StandardError; end

    # Validation errors for request parameters
    class ValidationError < StandardError; end
  end

  # Include all error classes at the module level for convenience
  include Errors
end