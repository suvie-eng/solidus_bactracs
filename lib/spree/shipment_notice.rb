module Spree

  class ShipmentNotice

    attr_reader :error, :number, :tracking

    def initialize(params)
      @number   = params[:order_number]
      @tracking = params[:tracking_number]
    end

    def apply
      locate ? update : not_found
    rescue => e
      handle_error(e)
    end

    private

    # TODO: add documentation
    # TODO: review Spree::Order.shipments logic
    # => <Shipment>
    def locate
      if Spree::Config.shipstation_number == :order
        @order = Spree::Order.find_by_number(number)
        # - need to find shipments that haven't been shipped
        # - need to then order by created_at so the oldest ones are most likely to be the onces processed first
        # @order.try(:shipments).order(created_at: :asc).first
        @shipment = @order.try(:shipments).try(:first)
      else
        @shipment = Spree::Shipment.find_by_number(number)
      end
    end

    # TODO: review logic here
    # TODO: update the shipment's order#shipping_state to "shipped" if all of that order's shipments
    #   have a status of "shipped"
    # => true
    def update
      @shipment.update_attribute(:tracking, tracking)

      unless @shipment.shipped?
        @shipment.reload.update_attribute(:state, 'shipped')
        @shipment.inventory_units.each(&:ship!)
        @shipment.touch :shipped_at
      end

      true
    end

    # TODO: add documentation
    # TODO: add logging
    # => false
    def not_found
      @error = I18n.t(:shipment_not_found, number: number)
      false
    end

    # TODO: add documentation
    # TODO: add logging
    # => false
    def handle_error(error)
      @error = I18n.t(:import_tracking_error, error: error.to_s)
      false
    end

  end

end
