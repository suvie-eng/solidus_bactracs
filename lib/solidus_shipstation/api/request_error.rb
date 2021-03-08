# frozen_string_literal: true

module SolidusShipstation
  module Api
    class RequestError < RuntimeError
      attr_reader :response_code, :response_body, :response_headers

      class << self
        def from_response(response)
          new(**options_from_response(response))
        end

        private

        def options_from_response(response)
          {
            response_code: response.code,
            response_headers: response.headers,
            response_body: response.body,
          }
        end
      end

      def initialize(response_code:, response_body:, response_headers:)
        @response_code = response_code
        @response_body = response_body
        @response_headers = response_headers

        super(response_body)
      end
    end
  end
end
