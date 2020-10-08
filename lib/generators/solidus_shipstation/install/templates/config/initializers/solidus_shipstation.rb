# frozen_string_literal: true

SolidusShipstation.configure do |config|
  # Choose between Grams, Ounces or Pounds.
  config.weight_units = "Grams"

  # ShipStation expects the endpoint to be protected by HTTP Basic Auth.
  # Set the username and password you desire for ShipStation to use.
  config.username = "smoking_jay_cutler"
  config.password = "my-awesome-password"

  # Capture payment when ShipStation notifies a shipping label creation.
  # Set this to `true` and `Spree::Config.require_payment_to_ship` to `false` if you
  # want to charge your customers at the time of shipment.
  config.capture_at_notification = false
end
