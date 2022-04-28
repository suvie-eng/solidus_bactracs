# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ThresholdVerifier
      class << self
        def call(shipment)
          return false unless shipment.order.completed?

          !!(shipment_requires_creation?(shipment) || shipment_requires_update?(shipment))
        end

        private

        def shipment_requires_creation?(shipment)
          shipment.backtracs_synced_at.nil? &&
            Time.zone.now - shipment.order.updated_at < SolidusBacktracs.config.api_sync_threshold
        end

        def shipment_requires_update?(shipment)
          shipment.backtracs_synced_at &&
            shipment.backtracs_synced_at < shipment.order.updated_at &&
            Time.zone.now - shipment.order.updated_at < SolidusBacktracs.config.api_sync_threshold
        end
      end
    end
  end
end
