# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "openssl"
require "base64"
require "time"

module BudaApi
  # Base client class providing core HTTP functionality and error handling
  class Client
    include Constants

    attr_reader :base_url, :timeout, :retries, :debug_mode

    DEFAULT_OPTIONS = {
      base_url: "https://www.buda.com/api/v2/",
      timeout: 30,
      retries: 3,
      debug_mode: false
    }.freeze

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @base_url = @options[:base_url]
      @timeout = @options[:timeout]
      @retries = @options[:retries]
      @debug_mode = @options[:debug_mode]

      setup_logger
      setup_http_client
    end

    protected

    # Make a GET request
    # @param path [String] API endpoint path
    # @param params [Hash] query parameters
    # @return [Hash] parsed response body
    def get(path, params = {})
      make_request(:get, path, params: params)
    end

    # Make a POST request  
    # @param path [String] API endpoint path
    # @param body [Hash] request body
    # @param params [Hash] query parameters
    # @return [Hash] parsed response body
    def post(path, body: {}, params: {})
      make_request(:post, path, body: body, params: params)
    end

    # Make a PUT request
    # @param path [String] API endpoint path  
    # @param body [Hash] request body
    # @param params [Hash] query parameters
    # @return [Hash] parsed response body
    def put(path, body: {}, params: {})
      make_request(:put, path, body: body, params: params)
    end

    # Make a DELETE request
    # @param path [String] API endpoint path
    # @param params [Hash] query parameters  
    # @return [Hash] parsed response body
    def delete(path, params = {})
      make_request(:delete, path, params: params)
    end

    private

    def setup_logger
      log_level = @debug_mode ? :debug : BudaApi.configuration.logger_level
      BudaApi::Logger.setup(level: log_level)
    end

    def setup_http_client
      @http_client = Faraday.new(url: @base_url) do |f|
        f.options.timeout = @timeout
        f.options.open_timeout = @timeout / 2
        
        f.request :json
        f.request :retry, 
          max: @retries,
          interval: 0.5,
          backoff_factor: 2,
          retry_statuses: [408, 429, 500, 502, 503, 504],
          methods: [:get, :post, :put, :delete]

        f.response :json, content_type: /\bjson$/
        f.adapter :net_http
      end
    end

    def make_request(method, path, body: nil, params: {}, headers: {})
      start_time = Time.now
      full_url = build_url(path, params)
      
      # Add authentication headers if this is an authenticated client
      headers = add_authentication_headers(method, path, body, headers) if respond_to?(:add_authentication_headers, true)

      BudaApi::Logger.log_request(method, full_url, headers: headers, body: body)

      response = @http_client.public_send(method) do |req|
        req.url path
        req.params = params if params.any?
        req.headers.merge!(headers)
        req.body = body.to_json if body && !body.empty?
      end

      duration = ((Time.now - start_time) * 1000).round(2)
      BudaApi::Logger.log_response(
        response.status, 
        headers: response.headers, 
        body: response.body,
        duration: duration
      )

      handle_response(response)

    rescue Faraday::ConnectionFailed => e
      error = ConnectionError.new("Connection failed: #{e.message}")
      BudaApi::Logger.log_error(error, context: { method: method, path: path })
      raise error

    rescue Faraday::TimeoutError => e
      error = TimeoutError.new("Request timed out: #{e.message}")
      BudaApi::Logger.log_error(error, context: { method: method, path: path })
      raise error

    rescue StandardError => e
      error = ApiError.new("Unexpected error: #{e.message}")
      BudaApi::Logger.log_error(error, context: { method: method, path: path })
      raise error
    end

    def build_url(path, params)
      url = @base_url + path.to_s
      return url if params.empty?

      query_string = params.map { |k, v| "#{k}=#{v}" }.join("&")
      "#{url}?#{query_string}"
    end

    def handle_response(response)
      case response.status
      when HttpStatus::OK, HttpStatus::CREATED
        validate_and_parse_response(response)
      when HttpStatus::BAD_REQUEST
        handle_error_response(BadRequestError, response, "Bad request")
      when HttpStatus::UNAUTHORIZED
        handle_error_response(AuthenticationError, response, "Authentication failed")
      when HttpStatus::FORBIDDEN  
        handle_error_response(AuthorizationError, response, "Forbidden - insufficient permissions")
      when HttpStatus::NOT_FOUND
        handle_error_response(NotFoundError, response, "Resource not found")
      when HttpStatus::UNPROCESSABLE_ENTITY
        handle_error_response(ValidationError, response, "Validation failed")
      when HttpStatus::RATE_LIMITED
        handle_error_response(RateLimitError, response, "Rate limit exceeded")
      when HttpStatus::INTERNAL_SERVER_ERROR..HttpStatus::GATEWAY_TIMEOUT
        handle_error_response(ServerError, response, "Server error")
      else
        handle_error_response(ApiError, response, "Unknown error")
      end
    end

    def validate_and_parse_response(response)
      body = response.body

      if body.nil? || body.empty?
        raise InvalidResponseError.new("Empty response body", status_code: response.status)
      end

      unless body.is_a?(Hash)
        raise InvalidResponseError.new("Invalid response format", 
                                     status_code: response.status, 
                                     response_body: body)
      end

      # Check for API error in successful HTTP response
      if body.key?("message") && body["message"]&.match?(/error/i)
        raise ApiError.new(body["message"], 
                          status_code: response.status, 
                          response_body: body)
      end

      body
    end

    def handle_error_response(error_class, response, default_message)
      error_message = extract_error_message(response.body) || default_message

      raise error_class.new(
        error_message,
        status_code: response.status,
        response_body: response.body,
        response_headers: response.headers.to_h
      )
    end

    def extract_error_message(body)
      return nil unless body.is_a?(Hash)

      # Try different common error message fields
      %w[message error error_message detail details].each do |field|
        return body[field] if body[field].is_a?(String) && !body[field].empty?
      end

      # Handle nested error structures
      if body["errors"].is_a?(Array) && body["errors"].any?
        return body["errors"].first if body["errors"].first.is_a?(String)
        return body["errors"].first["message"] if body["errors"].first.is_a?(Hash)
      end

      nil
    end

    # Validate required parameters
    def validate_required_params(params, required_fields)
      missing = required_fields.select { |field| params[field].nil? || params[field].to_s.empty? }
      return if missing.empty?

      raise ValidationError, "Missing required parameters: #{missing.join(', ')}"
    end

    # Validate parameter values against allowed options
    def validate_param_values(params, validations)
      validations.each do |param, allowed_values|
        value = params[param]
        next if value.nil?

        unless allowed_values.include?(value)
          raise ValidationError, 
                "Invalid #{param}: '#{value}'. Must be one of: #{allowed_values.join(', ')}"
        end
      end
    end

    # Clean and normalize parameters
    def normalize_params(params)
      params.reject { |_, v| v.nil? || v.to_s.empty? }
             .transform_keys(&:to_s)
             .transform_values { |v| v.is_a?(Symbol) ? v.to_s : v }
    end
  end
end