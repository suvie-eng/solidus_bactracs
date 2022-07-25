# frozen_string_literal: true

module SolidusBactracs
  module Spree
    module ShipmentDecorator
      def self.prepended(base)
        base.singleton_class.prepend ClassMethods
      end

      def verify_bactracs_sync!
        if bactracs_sync_verified_at.nil?
          # API call to verify RMAs of shipments
          if BactracsService.new.rma_was_synced?(self)
            self.update_column(:bactracs_sync_verified_at, Time.now)
          else
            self.update_column(:bactracs_synced_at, nil)
          end
        end
      rescue => e
        Rails.logger.error({ message: "#{e.message}, file: shipment_decorator.rb", shipment_number: number })
      end

      module ClassMethods
        def exportable
          ::Spree::Deprecation.warn <<~DEPRECATION
            `Spree::Shipment.exportable` is deprecated and will be removed in a future version
            of solidus_bactracs. Please use `SolidusBactracs::Shipment::ExportableQuery.apply`.
          DEPRECATION

          SolidusBactracs::Shipment::ExportableQuery.apply(self)
        end

        def between(from, to)
          ::Spree::Deprecation.warn <<~DEPRECATION
            `Spree::Shipment.between` is deprecated and will be removed in a future version
            of solidus_bactracs. Please use `SolidusBactracs::Shipment::BetweenQuery.apply`.
          DEPRECATION

          SolidusBactracs::Shipment::BetweenQuery.apply(self, from: from, to: to)
        end
      end

      ::Spree::Shipment.prepend self
    end
  end
end
