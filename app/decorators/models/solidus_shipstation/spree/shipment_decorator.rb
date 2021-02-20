# frozen_string_literal: true

module SolidusShipstation
  module Spree
    module ShipmentDecorator
      def self.prepended(base)
        base.singleton_class.prepend ClassMethods
      end

      module ClassMethods
        def exportable
          ::Spree::Deprecation.warn <<~DEPRECATION
            `Spree::Shipment.exportable` is deprecated and will be removed in a future version
            of solidus_shipstation. Please use `SolidusShipstation::Shipment::ExportableQuery.apply`.
          DEPRECATION

          SolidusShipstation::Shipment::ExportableQuery.apply(self)
        end

        def between(from, to)
          condition = <<~SQL.squish
            (spree_shipments.updated_at > :from AND spree_shipments.updated_at < :to) OR
            (spree_orders.updated_at > :from AND spree_orders.updated_at < :to)
          SQL

          joins(:order).where(condition, from: from, to: to)
        end
      end

      ::Spree::Shipment.prepend self
    end
  end
end
