# frozen_string_literal: true

module SolidusBactracs
  module Shipment
    class ExportableQuery
      def self.apply(scope)
        scope = scope
                .order(:updated_at)
                .joins(:order)
                .merge(::Spree::Order.complete)

        unless SolidusBactracs.configuration.capture_at_notification
          scope = scope.where(spree_shipments: { state: ['ready', 'canceled'] })
        end

        unless SolidusBactracs.configuration.export_canceled_shipments
          scope = scope.where.not(spree_shipments: { state: 'canceled' })
        end

        scope
      end
    end
  end
end
