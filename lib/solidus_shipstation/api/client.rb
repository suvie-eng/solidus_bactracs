# frozen_string_literal: true

module SolidusShipstation
  module Api
    class Client
      def self.from_config
        new(request_runner: RequestRunner.from_config)
      end

      attr_reader :request_runner

      def initialize(request_runner:)
        @request_runner = request_runner
      end

      def bulk_create_orders(shipments)
        params = shipments.map do |shipment|
          Serializer.serialize_shipment(shipment)
        end

        request_runner.call(:post, '/orders/createorders', params)
      end
    end
  end
end
