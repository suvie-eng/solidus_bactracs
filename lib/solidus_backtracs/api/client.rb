# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class Client
      class << self
        def from_config
          new(
            request_runner: RequestRunner.from_config,
            error_handler: SolidusBacktracs.config.error_handler,
            shipment_serializer: SolidusBacktracs.config.api_shipment_serializer,
          )
        end
      end

      attr_reader :request_runner, :error_handler, :shipment_serializer

      def initialize(request_runner:, error_handler:, shipment_serializer:)
        @request_runner = request_runner
        @error_handler = error_handler
        @shipment_serializer = shipment_serializer
      end

      def bulk_create_orders(shipments)
        shipments.each do |shipment|
          SolidusBacktracs::Api::SyncShipmentJob.perform_async(shipment.id)
        end.compact
      end
    end
  end
end
