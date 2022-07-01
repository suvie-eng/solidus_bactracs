# frozen_string_literal: true

module SolidusBactracs
  module Spree
    module ShipmentDecorator
      def self.prepended(base)
        base.singleton_class.prepend ClassMethods
      end

      module ClassMethods
        def exportable
          ::Spree::Deprecation.warn <<~DEPRECATION
            `Spree::Shipment.exportable` is deprecated and will be removed in a future version
            of solidus_backtracs. Please use `SolidusBactracs::Shipment::ExportableQuery.apply`.
          DEPRECATION

          SolidusBactracs::Shipment::ExportableQuery.apply(self)
        end

        def between(from, to)
          ::Spree::Deprecation.warn <<~DEPRECATION
            `Spree::Shipment.between` is deprecated and will be removed in a future version
            of solidus_backtracs. Please use `SolidusBactracs::Shipment::BetweenQuery.apply`.
          DEPRECATION

          SolidusBactracs::Shipment::BetweenQuery.apply(self, from: from, to: to)
        end
      end

      ::Spree::Shipment.prepend self
    end
  end
end
