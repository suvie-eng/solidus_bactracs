# frozen_string_literal: true

SolidusBacktracs.configure do |config|
  # Choose between Grams, Ounces or Pounds.
  config.weight_units = "Grams"

  # Capture payment when Backtracs notifies a shipping label creation.
  # Set this to `true` and `Spree::Config.require_payment_to_ship` to `false` if you
  # want to charge your customers at the time of shipment.
  config.capture_at_notification = false

  ## API Configuration
  config.api_base = ENV['BACKTRACS_API_BASE'] || 'https://bactracstest.andlor.com'

  # Backtracs expects the endpoint to be protected by HTTP Basic Auth.
  # Set the username and password you desire for Backtracs to use.
  config.webhook_username = "smoking_jay_cutler"
  config.webhook_password = "my-awesome-password"

  ## Proxy
  config.proxy_address = ENV['PROXY_ADDRESS']
  config.proxy_port = ENV['PROXY_PORT']
  config.proxy_username = ENV['PROXY_USER']
  config.proxy_password = ENV['PROXY_PASS']

  ## Authentication Service Credentials
  config.authentication_username = "red_blue_jay"
  config.authentication_password = "my-secret-other-password"


  ## Shipment Serializer Configuration
  config.sku_map = {}
  config.default_rma_type = "W"
  config.default_carrier = "FedExGrnd"
  config.default_ship_method = "GROUND"  
  config.default_status = "OPEN"
  config.default_rp_location = "FG-NEW"
  config.shippable_skus = []

  ####### XML integration
  # Only uncomment these lines if you're going to use the XML integration.

  # Export canceled shipments to Backtracs
  # Set this to `true` if you want canceled shipments included in the endpoint.
  # config.export_canceled_shipments = false

  # You can customize the class used to receive notifications from the POST request
  # Make sure it has a class method `from_payload` which receives the notification hash
  # and an instance method `apply`
  # config.shipment_notice_class = 'SolidusBacktracs::ShipmentNotice'

  ####### API integration
  # Only uncomment these lines if you're going to use the API integration.

  # Override the shipment serializer used for API sync. This can be any object
  # that responds to `#call`. At the very least, you'll need to uncomment the
  # following lines and customize your store ID.
  # config.api_shipment_serializer = proc do |shipment|
  #   SolidusBacktracs::Api::ShipmentSerializer.new(store_id: '12345678').call(shipment)
  # end

  # Override the logic used to match a Backtracs order to a shipment from a
  # given collection. This can be useful when you override the default serializer
  # and change the logic used to generate the order number.
  # config.api_shipment_matcher = proc do |backtracs_order, shipments|
  #   shipments.find { |shipment| shipment.number == backtracs_order['orderNumber'] }
  # end

  # API key and secret for accessing the Backtracs API.
  # config.api_key = "api-key"
  # config.api_secret = "api-secret"

  # Number of shipments to import into Backtracs at once.
  # If unsure, leave this set to 100, which is the maximum
  # number of shipments that can be imported at once.
  config.api_batch_size = 100

  # Period of time after which the integration will "drop" shipments and stop
  # trying to create/update them. This prevents the API from retrying indefinitely
  # in case an error prevents some shipments from being created/updated.
  config.api_sync_threshold = 7.days

  # Error handler used by the API integration for certain non-critical errors (e.g.
  # a failure when serializing a shipment from a batch). This should be a proc that
  # accepts an exception and a context hash. Popular options for error handling are
  # logging or sending the error to an error tracking tool such as Sentry.
  config.error_handler = -> (error, context = {}) {
    Sentry.capture_exception(error, extra: context)
  }
end
