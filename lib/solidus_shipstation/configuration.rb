# frozen_string_literal: true

module SolidusShipstation
  class Configuration
    attr_accessor(
      :username,
      :password,
      :weight_units,
      :ssl_encrypted,
      :capture_at_notification,
      :export_canceled_shipments,
      :api_store_id,
      :custom_api_params,
      :api_username,
      :api_password
    )

    def initialize
      @custom_api_params = ->(_shipment) { {} }
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
