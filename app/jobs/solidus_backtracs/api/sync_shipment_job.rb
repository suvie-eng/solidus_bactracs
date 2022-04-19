# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class SyncShipmentJob < ApplicationJob
      queue_as :default

      def perform(shipment_id)
        shipment = Spree::Shipment.find(shipment_id)
        serializer = shipment_serializer.new(shipment: shipment)
        request_runner.authenticated_call(method: :post, path: '/orders/createorders', params: params, serializer: serializer)
      rescue StandardError => e
        error_handler.call(e, shipment: shipment)
        nil
      end
    end
  end
end
