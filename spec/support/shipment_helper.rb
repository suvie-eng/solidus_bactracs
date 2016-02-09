module Spree

  module ShipmentHelper

    def create_shipment(options = {})
      FactoryGirl.create(:shipment, options).tap do |shipment|
        shipment.update_column(:state, options[:state]) if options[:state]
      end
    end

  end

end
