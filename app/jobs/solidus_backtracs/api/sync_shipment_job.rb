# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class SyncShipmentJob < ApplicationJob
      queue_as :default

      def perform(shipment_id: nil, error_handler: nil, shipment_serializer: nil, request_runner: nil)
        shipment = ::Spree::Shipment.find(shipment_id)
        request_runner.authenticated_call(method: :post, path: '/webservices/rma/rmaservice.asmx', serializer: shipment_serializer, shipment: shipment)
      rescue StandardError => e
        error_handler.call(e, shipment: shipment)
        nil
      end
    end
  end
end
