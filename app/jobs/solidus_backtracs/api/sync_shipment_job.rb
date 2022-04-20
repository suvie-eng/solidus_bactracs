# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class SyncShipmentJob < ApplicationJob
      queue_as :default

      def perform(shipment: nil, error_handler: nil, shipment_serializer: nil)
        serializer = shipment_serializer.new(shipment: shipment)
        request_runner.new.authenticated_call(method: :post, path: '/webservices/rma/rmaservice.asmx', serializer: serializer)
      rescue StandardError => e
        error_handler.call(e, shipment: shipment)
        nil
      end
    end
  end
end
