# frozen_string_literal: true

module SolidusBactracs
  module Api
    class SyncShipmentsJob# < ApplicationJob
      include Sidekiq::Worker

      sidekiq_options queue: 'default'

      def perform(shipment_ids)
        shipments = ::Spree::Shipment.where(id: shipment_ids)
        shipments = select_shipments(shipments)
        return if shipments.empty?

        sync_shipments(shipments)

        # Verify bactracs sync
        shipments.each { |shipment| worker_klass.perform_sync(shipment.id) }

      rescue RateLimitedError => e
        self.class.set(wait: e.retry_in).perform_async
      rescue StandardError => e
        SolidusBactracs.config.error_handler.call(e, {})
      end

      private

      def select_shipments(shipments)
        shipments.select do |shipment|
          if ThresholdVerifier.call(shipment)
            true
          else
            ::Spree::Event.fire(
              'solidus_bactracs.api.sync_skipped',
              shipment: shipment,
            )

            false
          end
        end
      end

      def worker_klass
        @worker_klass ||= SolidusBactracs.config.api_verify_worker.constantize
      end

      def sync_shipments(shipments)
        BatchSyncer.from_config.call(shipments)
      end
    end
  end
end
