# frozen_string_literal: true

SolidusShipstation.configure do |config|
  # Choose between Grams, Ounces or Pounds.
  config.weight_units = "Grams"

  # Capture payment when ShipStation notifies a shipping label creation.
  # Set this to `true` and `Spree::Config.require_payment_to_ship` to `false` if you
  # want to charge your customers at the time of shipment.
  config.capture_at_notification = false

  # ShipStation expects the endpoint to be protected by HTTP Basic Auth.
  # Set the username and password you desire for ShipStation to use.
  config.username = "smoking_jay_cutler"
  config.password = "my-awesome-password"

  ####### XML integration
  # Only uncomment these lines if you're going to use the XML integration.

  # Export canceled shipments to ShipStation
  # Set this to `true` if you want canceled shipments included in the endpoint.
  # config.export_canceled_shipments = false

  # You can customize the class used to receive notifications from the POST request
  # Make sure it has a class method `from_payload` which receives the notification hash
  # and an instance method `apply`
  # config.shipment_notice_class = 'SolidusShipstation::ShipmentNotice'

  ####### API integration
  # Only uncomment these lines if you're going to use the API integration.

  # Override the shipment serializer used for API sync. This can be any object
  # that responds to `#call`. At the very least, you'll need to uncomment the
  # following lines and customize your store ID.
  # config.api_shipment_serializer = proc do |shipment|
  #   SolidusShipstation::Api::ShipmentSerializer.new(store_id: '12345678').call(shipment)
  # end

  # Override the logic used to match a ShipStation order to a shipment from a
  # given collection. This can be useful when you override the default serializer
  # and change the logic used to generate the order number.
  # config.api_shipment_matcher = proc do |shipstation_order, shipments|
  #   shipments.find { |shipment| shipment.number == shipstation_order['orderNumber'] }
  # end

  # API key and secret for accessing the ShipStation API.
  # config.api_key = "api-key"
  # config.api_secret = "api-secret"

  # Number of shipments to import into ShipStation at once.
  # If unsure, leave this set to 100, which is the maximum
  # number of shipments that can be imported at once.
  # config.api_batch_size = 100

  # Period of time after which the integration will "drop" shipments and stop
  # trying to create/update them. This prevents the API from retrying indefinitely
  # in case an error prevents some shipments from being created/updated.
  # config.api_sync_threshold = 7.days

  # Error handler used by the API integration for certain non-critical errors (e.g.
  # a failure when serializing a shipment from a batch). This should be a proc that
  # accepts an exception and a context hash. Popular options for error handling are
  # logging or sending the error to an error tracking tool such as Sentry.
  # config.error_handler = -> (error, context = {}) {
  #   Sentry.capture_exception(error, extra: context)
  # }
end
