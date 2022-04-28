# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ScheduleShipmentSyncsJob < ApplicationJob
      queue_as :default

      def perform
        shipments = SolidusBacktracs::Shipment::PendingApiSyncQuery.apply(
          ::Spree::Shipment
            .joins(inventory_units: [:variant])
            .where("spree_variants.sku" => ["SUVIE201R", "SUVIE201RB"])
            .where.not(shipstation_order_id: nil)
            .distinct
          )

        shipments.find_in_batches(batch_size: SolidusBacktracs.config.api_batch_size) do |batch|
          SyncShipmentsJob.perform_later(batch.to_a)
        end
      rescue StandardError => e
        SolidusBacktracs.config.error_handler.call(e, {})
      end
    end
  end
end
