# frozen_string_literal: true
require "uri"
require "net/http"

module SolidusBactracs
  module Api
    class RequestRunner

      def initialize
        @username = SolidusBactracs.configuration.authentication_username
        @password = SolidusBactracs.configuration.authentication_password
        @api_base = SolidusBactracs.configuration.api_base
        @retries  = SolidusBactracs.configuration.api_retries
      end

      def authenticated_call(method: nil, path: nil, serializer: nil, shipment: nil, count: 0)
        if count <= @retries
          unless @username.present? || @password.present? || @api_base.present?
            raise "Credentials not defined for Authentication"
          end

          @response = Rails.cache.fetch("backtracks_cache_key", expires_in: 1.hour, skip_nil: true) do
            self.call(method: :get, path: "/webservices/user/Authentication.asmx/Login?sUserName=#{@username}&sPassword=#{@password}")
          end

          raise RequestError.from_response(@response) unless @response # just try again for @retries?
          authenticted = parse_authentication_response(@response, "Result")
          raise RequestError.from_response(@response) if authenticted == "false"
          sguid = parse_authentication_response(@response, "Message")

          if authenticted == 'false'
            clear_cache
            raise "User Not Authenticated"
          else
            sguid = parse_authentication_response(@response, "Message")
            params = serializer.call(shipment, sguid)

            rma_response = call(method: :post, path: path, params: params)
            unless parse_rma_creation_response(rma_response) == 'true'
              clear_cache
              count += 1
              self.authenticated_call(method: :post, path: '/webservices/rma/rmaservice.asmx', serializer: serializer, shipment: shipment, count: count)
            end
            shipment_synced(shipment)
          end
        else
          shipment_sync_failed(shipment)
        end
      end

      def call(method: nil, path: nil, params: {})
        doc = {}
        if params.present?
          doc = Nokogiri::XML(params.to_s)
        end
        response = HTTParty.send(
          method,
          URI.join(@api_base, path),
          body: doc.to_xml,
          http_proxyaddr: SolidusBactracs.configuration.proxy_address,
          http_proxyport: SolidusBactracs.configuration.proxy_port,
          http_proxyuser: SolidusBactracs.configuration.proxy_username,
          http_proxypass: SolidusBactracs.configuration.proxy_password,
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

      def clear_cache
        Rails.cache.delete('bactracks_cache_key')
        @response = nil
      end

      def parse_authentication_response(response, type)
        response.dig("AuthenticationResponse", type)
      end

      def parse_rma_creation_response(response)
        response.dig("Envelope", "Body", "CreateNewResponse", "CreateNewResult", "Result")
      end

      def shipment_synced(shipment)
        shipment.update_column(:bactracs_synced_at, Time.zone.now)

        ::Spree::Event.fire(
          'solidus_bactracs.api.sync_completed',
          shipment: shipment
        )
      end

      def shipment_sync_failed(shipment)
        ::Spree::Event.fire(
          'solidus_bactracs.api.sync_failed',
          shipment: shipment
        )
      end
    end
  end
end
