# frozen_string_literal: true

module SolidusBactracs
  module Api
    class ScheduleShipmentSyncsJob < ApplicationJob
      queue_as :default

      def perform
        shipments = query_shipments
        Rails.logger.info("#{self.class.name} - #{shipments.count} shipments to sync to Bactracs")

        shipments.find_in_batches(batch_size: SolidusBactracs.config.api_batch_size) do |batch|
          SyncShipmentsJob.perform_later(batch.to_a, false)
        end
      rescue StandardError => e
        SolidusBactracs.config.error_handler.call(e, {})
      end

      def shippable_skus
        SolidusBactracs.config.shippable_skus.present? ? SolidusBactracs.config.shippable_skus : Spree::Variant.pluck(:sku)
      end

      def query_shipments
        shipments = SolidusBactracs::Shipment::PendingApiSyncQuery.apply(all_elegible_shipments)
      end

      def all_elegible_shipments(skus: SolidusBactracs.config.shippable_skus, state: :ready)
        ::Spree::Shipment
            .joins(inventory_units: [:variant])
            .where("spree_variants.sku" => skus)
            .where("spree_shipments.state" => state)
            .where(bactracs_synced_at: nil)
            .distinct
      end
    end
  end
end
