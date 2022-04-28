# frozen_string_literal: true

module SolidusBacktracs
  class Configuration
    attr_accessor(
      :webhook_username,
      :webhook_password,
      :weight_units,
      :ssl_encrypted,
      :capture_at_notification,
      :export_canceled_shipments,
      :api_batch_size,
      :api_sync_threshold,
      :api_shipment_serializer,
      :api_key,
      :api_secret,
      :api_shipment_matcher,
      :error_handler,
      :shipment_notice_class,
      :authentication_username,
      :authentication_password,
      :api_base, 
      :proxy_address,
      :proxy_port,
      :proxy_username,
      :proxy_password,
      :default_carrier,
      :default_ship_method,
      :default_rp_location,
      :default_status,
      :sku_map,
      :default_rma_type
    )

    def initialize
      @api_batch_size = 100
      @api_sync_threshold = 7.days
      @error_handler = ->(_error, _extra = {}) {
        Rails.logger.error "#{error.inspect} (#{extra.inspect})"
      }
      @api_shipment_matcher = proc do |backtracs_order, shipments|
        shipments.find { |shipment| shipment.number == backtracs_order['orderNumber'] }
      end

      @shipment_notice_class = 'SolidusBacktracs::ShipmentNotice'
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
    end
  end
end