module SolidusShipstation
  class Configuration
    attr_accessor(
      :shipstation_username, :shipstation_password, :shipstation_weight_units,
      :shipstation_ssl_encrypted, :shipstation_capture_at_notification,
    )
  end
end
