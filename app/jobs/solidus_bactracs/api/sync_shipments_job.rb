# frozen_string_literal: true

module SolidusBactracs
  module Api
    class SyncShipmentsJob < ApplicationJob
      queue_as :default

      def perform(shipments, is_trade_up)
        shipments = select_shipments(shipments)
        return if shipments.empty?

        sync_shipments(shipments, is_trade_up)

        # Verify bactracs sync
        unless is_trade_up?
          shipments.each { |shipment| VerifyBactracsSyncWorker.perform_async(shipment.id) }
        end

      rescue RateLimitedError => e
        self.class.set(wait: e.retry_in).perform_later
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

      def sync_shipments(shipments, is_trade_up)
        BatchSyncer.from_config.call(shipments, is_trade_up)
      end
    end
  end
end
