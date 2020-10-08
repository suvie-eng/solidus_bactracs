# frozen_string_literal: true

SolidusShipstation.configure do |config|
  # Choose between Grams, Ounces or Pounds.
  config.shipstation_weight_units = "Grams"

  # ShipStation expects the endpoint to be protected by HTTP Basic Auth.
  # Set the username and password you desire for ShipStation to use.
  config.shipstation_username = "smoking_jay_cutler"
  config.shipstation_password = "my-awesome-password"

  # Turn SSL on/off for testing and development purposes.
  config.shipstation_ssl_encrypted = !Rails.env.development?

  # Capture payment when ShipStation notifies a shipping label creation.
  # Set this to `true` and `require_payment_to_ship` to `false` if you
  # want to charge your customers at the time of shipment.
  config.shipstation_capture_at_notification = false
end
