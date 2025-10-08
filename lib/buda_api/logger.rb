# frozen_string_literal: true

require "logger"

module BudaApi
  # Centralized logging functionality for the SDK
  class Logger
    LOG_LEVELS = {
      debug: ::Logger::DEBUG,
      info: ::Logger::INFO,
      warn: ::Logger::WARN,
      error: ::Logger::ERROR,
      fatal: ::Logger::FATAL
    }.freeze

    class << self
      attr_accessor :logger

      # Initialize the logger
      def setup(level: :info, output: $stdout)
        @logger = ::Logger.new(output)
        @logger.level = LOG_LEVELS[level] || LOG_LEVELS[:info]
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)} BudaApi: #{msg}\n"
        end
        @logger
      end

      # Log debug messages
      def debug(message)
        current_logger.debug(message)
      end

      # Log info messages
      def info(message)
        current_logger.info(message)
      end

      # Log warning messages  
      def warn(message)
        current_logger.warn(message)
      end

      # Log error messages
      def error(message)
        current_logger.error(message)
      end

      # Log fatal messages
      def fatal(message)
        current_logger.fatal(message)
      end

      # Log HTTP requests in debug mode
      def log_request(method, url, headers: {}, body: nil)
        return unless debug_enabled?

        debug("→ #{method.upcase} #{url}")
        debug("→ Headers: #{headers}") if headers&.any?
        debug("→ Body: #{body}") if body
      end

      # Log HTTP responses in debug mode
      def log_response(status, headers: {}, body: nil, duration: nil)
        return unless debug_enabled?

        debug("← #{status}")
        debug("← Headers: #{headers}") if headers&.any?
        debug("← Body: #{truncate_body(body)}") if body
        debug("← Duration: #{duration}ms") if duration
      end

      # Log errors with full context
      def log_error(error, context: {})
        error_msg = "Error: #{error.class.name} - #{error.message}"
        error_msg += "\nContext: #{context}" if context&.any?
        error_msg += "\nBacktrace:\n  #{error.backtrace.join("\n  ")}" if error.backtrace

        error(error_msg)
      end

      private

      def current_logger
        @logger || setup
      end

      def debug_enabled?
        current_logger.level <= ::Logger::DEBUG
      end

      def truncate_body(body, limit: 1000)
        return body unless body.is_a?(String) && body.length > limit

        "#{body[0...limit]}... (truncated)"
      end
    end
  end
end