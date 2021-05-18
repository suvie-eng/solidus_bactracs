# frozen_string_literal: true

module SolidusShipstation
  module Api
    class Client
      class << self
        def from_config
          new(
            request_runner: RequestRunner.from_config,
            error_handler: SolidusShipstation.config.error_handler,
          )
        end
      end

      attr_reader :request_runner, :error_handler

      def initialize(request_runner:, error_handler:)
        @request_runner = request_runner
        @error_handler = error_handler
      end

      def bulk_create_orders(shipments)
        params = shipments.map do |shipment|
          Serializer.serialize_shipment(shipment)
        rescue StandardError => e
          error_handler.call(e, shipment: shipment)
          nil
        end.compact

        return if params.empty?

        request_runner.call(:post, '/orders/createorders', params)
      end
    end
  end
end
