# frozen_string_literal: true

SolidusShipstation.configure do |config|
  # Choose between Grams, Ounces or Pounds.
  config.weight_units = "Grams"

  # Capture payment when ShipStation notifies a shipping label creation.
  # Set this to `true` and `Spree::Config.require_payment_to_ship` to `false` if you
  # want to charge your customers at the time of shipment.
  config.capture_at_notification = false

  ####### XML integration
  # Only uncomment these lines if you're going to use the XML integration.

  # ShipStation expects the endpoint to be protected by HTTP Basic Auth.
  # Set the username and password you desire for ShipStation to use.
  # config.username = "smoking_jay_cutler"
  # config.password = "my-awesome-password"

  # Export canceled shipments to ShipStation
  # Set this to `true` if you want canceled shipments included in the endpoint.
  # config.export_canceled_shipments = false

  ####### API integration
  # Only uncomment these lines if you're going to use the API integration.

  # Username and password for accessing the ShipStation API.
  # config.api_username = "api-user"
  # config.api_password = "api-pass"

  # ID of the store where you want to import your shipments.
  # This can be a literal value or an object that responds to `#call`.
  # config.api_store_id = -> (shipment) { "123456" }

  # Number of shipments to import into ShipStation at once.
  # If unsure, leave this set to 100, which is the maximum
  # number of shipments that can be imported at once.
  # config.api_batch_size = 100

  # Period of time after which the integration will "drop" shipments and stop
  # trying to create/update them. This prevents the API from retrying indefinitely
  # in case an error prevents some shipments from being created/updated.
  # config.api_sync_threshold = 7.days

  # Custom parameters that you want to include in the API payload, when
  # creating or updating a shipment in ShipStation.
  # config.custom_api_params = -> (shipment) {
  #   {
  #     gift: shipment.order.gift?,
  #     giftMessage: shipment.order.gift_note,
  #   }
  # }

  # Error handler used by the API integration for certain non-critical errors (e.g.
  # a failure when serializing a shipment from a batch). This should be a proc that
  # accepts an exception and a context hash. Popular options for error handling are
  # logging or sending the error to an error tracking tool such as Sentry.
  # config.error_handler = -> (error, context = {}) {
  #   Sentry.capture_exception(error, extra: context)
  # }
end
