# frozen_string_literal: true

module SolidusBacktracs
  module Shipment
    class ExportableQuery
      def self.apply(scope)
        scope = scope
                .order(:updated_at)
                .joins(:order)
                .merge(::Spree::Order.complete)

        unless SolidusBacktracs.configuration.capture_at_notification
          scope = scope.where(spree_shipments: { state: ['ready', 'canceled'] })
        end

        unless SolidusBacktracs.configuration.export_canceled_shipments
          scope = scope.where.not(spree_shipments: { state: 'canceled' })
        end

        scope
      end
    end
  end
end
