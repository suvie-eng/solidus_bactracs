# frozen_string_literal: true

module SolidusShipstation
  module Api
    class SyncShipmentsJob < ApplicationJob
      queue_as :default

      def perform(shipments)
        shipments = select_shipments(shipments)
        return if shipments.empty?

        sync_shipments(shipments)
      rescue RateLimitedError => e
        self.class.set(wait: e.retry_in).perform_later
      end

      private

      def select_shipments(shipments)
        shipments.select do |shipment|
          if ThresholdVerifier.call(shipment)
            true
          else
            ::Spree::Event.fire(
              'solidus_shipstation.api.sync_skipped',
              shipment: shipment,
            )

            false
          end
        end
      end

      def sync_shipments(shipments)
        BatchSyncer.from_config.call(shipments)
      end
    end
  end
end
