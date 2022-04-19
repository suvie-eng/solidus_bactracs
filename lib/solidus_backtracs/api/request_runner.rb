# frozen_string_literal: true
require "uri"
require "net/http"

module SolidusBacktracs
  module Api
    class RequestRunner

      def initialize
        @username = ENV['BACTRACS_USERNAME']
        @password = ENV['BACTRACS_PASSWORD']
        @api_base = ENV['BACTRACS_API_BASE']
      end

      def authenticated_call(method: nil, path: nil, serializer: nil)
        Rails.cache.fetch("backtracks_cache_key", expires_in: 1.hour) do
          response = self.call(method: :get, path: "/user/Authentication.asmx/Login?sUserName=#{@username}&sPassword=#{@password}")
        end

        sguid = # parse sguid here

        params = serializer.call(sguid: sguid)

        call(method: :post, path: path, params: params)
      end

      def call(method: nil, path: nil, params: {}, proxy: nil)

        # HTTP Proxy docs
        # https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb
        # TODO: Format correctly and fill in HTTP proxy details.
        # TODO: Allow configuring HTTP proxy in configuration
        response = HTTParty.send(
          method,
          URI.join(@api_base, path),
          body: params.to_json,
          http_proxy_addr: # Fill out details,
          basic_auth: {
            username: @username,
            password: @password,
          },
          headers: {
            'Content-Type' => 'application/xml',
            'Accept' => 'application/xml',
          },
        )


        case response.code.to_s
        when /2\d{2}/
          parse_respone(response)
        when '429'
          raise RateLimitedError.from_response(response)
        else
          raise RequestError.from_response(response)
        end
      end

      def parse_respone(response)
        doc = Nokogiri::XML(response.body.squish)
        doc.xpath('//xmlns:AuthenticationResponse//xmlns:Message').inner_text
      end
    end
  end
end
