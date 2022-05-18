# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ScheduleShipmentSyncsJob < ApplicationJob
      queue_as :default

      def perform
        shipments = query_shipments

        shipments.find_in_batches(batch_size: SolidusBacktracs.config.api_batch_size) do |batch|
          SyncShipmentsJob.perform_later(batch.to_a)
        end
      rescue StandardError => e
        SolidusBacktracs.config.error_handler.call(e, {})
      end

      def shippable_skus
        SolidusBacktracs.config.shippable_skus.present? ? SolidusBacktracs.config.shippable_skus : Spree::Variant.pluck(:sku)
      end

      def query_shipments
        shipments = SolidusBacktracs::Shipment::PendingApiSyncQuery.apply(
          ::Spree::Shipment
            .joins(inventory_units: [:variant])
            .where("spree_variants.sku" => SolidusBacktracs.config.shippable_skus)
            .where("spree_shipments.state" => :ready)
            .where(backtracs_synced_at: nil)
            .distinct
        )
      end
    end
  end
end

