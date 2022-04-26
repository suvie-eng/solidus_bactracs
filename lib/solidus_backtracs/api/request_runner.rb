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

          rma_response = call(method: :post, path: path, params: params)
          sync_shipment(shipment, rma_response)
        end
      end

      def call(method: nil, path: nil, params: {}, proxy: nil)
        doc = {}
        if params.present?
          doc = Nokogiri::XML(params.to_s)
        end
        response = HTTParty.send(
          method,
          URI.join(@api_base, path),
          body: doc.to_xml,
          http_proxyaddr: SolidusBacktracs.configuration.proxy_address,
          http_proxyport: SolidusBacktracs.configuration.proxy_port,
          http_proxyuser: SolidusBacktracs.configuration.proxy_username,
          http_proxypass: SolidusBacktracs.configuration.proxy_password,
          headers: {
            'Content-Type' => 'text/xml',
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

      def sync_shipment(shipment, response)
        result = response.dig("Envelope", "Body", "CreateNewResponse", "CreateNewResult", "Result")
        if result == 'true'
          shipment.update_column(:backtracs_synced_at, Time.zone.now)

          ::Spree::Event.fire(
            'solidus_backtracs.api.sync_completed',
            shipment: shipment
          )
        else
          ::Spree::Event.fire(
            'solidus_backtracs.api.sync_failed',
            shipment: shipment
          )
        end
      end
    end
  end
end
