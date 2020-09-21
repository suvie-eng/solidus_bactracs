module ConfigurationHelper
  def stub_configuration(options)
    allow(SolidusShipstation.configuration).to receive_messages(options)

    if options[:capture_at_notification]
      stub_spree_preferences(require_payment_to_ship: false)
    end
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelper
end
