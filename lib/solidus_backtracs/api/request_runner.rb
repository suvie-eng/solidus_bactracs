# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class RequestRunner

      def initialize
        @username = SolidusBacktracs.configuration.authentication_username
        @password = SolidusBacktracs.configuration.authentication_password
        @api_base = SolidusBacktracs.configuration.api_base
      end

      def authenticated_call(method: nil, path: nil, serializer: nil, shipment: nil)
        unless @username.present? || @password.present? || @api_base.present?
          raise "Credentials not defined for Authentication"
        end 

        Rails.cache.fetch("backtracks_cache_key", expires_in: 1.hour) do
          @response = self.call(method: :get, path: "/webservices/user/Authentication.asmx/Login?sUserName=#{@username}&sPassword=#{@password}")
        end

        authenticted = parse_response(@response, "Result")

        case authenticted
        when 'false'
          raise RequestError.from_response(@response)
        else
          sguid = parse_response(@response, "Message")
          params = serializer.call(shipment, sguid)

          call(method: :post, path: path, params: params)
        end
      end

      def call(method: nil, path: nil, params: {}, proxy: nil)
        response = HTTParty.send(
          method,
          URI.join(@api_base, path),
          body: params.to_json,
          http_proxyaddr: SolidusBacktracs.configuration.proxy_address,
          http_proxyport: SolidusBacktracs.configuration.proxy_port,
          http_proxyuser: SolidusBacktracs.configuration.proxy_username,
          http_proxypass: SolidusBacktracs.configuration.proxy_password,
          headers: {
            'Content-Type' => 'application/xml',
            'Accept' => 'application/xml',
          },
        )

        case response.code.to_s
        when /2\d{2}/
          response
        when '429'
          raise RateLimitedError.from_response(response)
        else
          raise RequestError.from_response(response)
        end
      end

      def parse_response(response, type)
        doc = Nokogiri::XML(response.body.squish)
        doc.xpath("//xmlns:AuthenticationResponse//xmlns:#{type}").inner_text
      end
    end
  end
end
