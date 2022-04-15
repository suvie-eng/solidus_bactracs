# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class RequestRunner
      #TODO
      API_BASE = 'https://bactracstest.andlor.com'

      attr_reader :username, :password

      class << self
        def from_config
          new(
            username: SolidusBacktracs.config.api_key,
            password: SolidusBacktracs.config.api_secret,
          )
        end
      end

      def initialize(username:, password:)
        @username = username
        @password = password
      end

      def call(method, path, params = {})
        response = HTTParty.send(
          method,
          URI.join(API_BASE, path),
          body: params.to_json,
          basic_auth: {
            username: @username,
            password: @password,
          },
          headers: {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
          },
        )

        case response.code.to_s
        when /2\d{2}/
          response.parsed_response
        when '429'
          raise RateLimitedError.from_response(response)
        else
          raise RequestError.from_response(response)
        end
      end
    end
  end
end
