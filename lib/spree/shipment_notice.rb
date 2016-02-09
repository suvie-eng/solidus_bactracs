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
    # => <Shipment>
    def locate
      @shipment = Spree::Shipment.find_by(number: number)
    end

    # TODO: add documentation
    # TODO: update via state_machine
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
