require 'spec_helper'

RSpec.describe SolidusShipstation::Engine do

  describe 'configuration methods' do
    it 'creates Spree::Config methods', :aggregate_failures do
      expect(Spree::Config).to respond_to(:shipstation_username)
      expect(Spree::Config).to respond_to(:shipstation_password)
      expect(Spree::Config).to respond_to(:shipstation_weight_units)
      expect(Spree::Config).to respond_to(:shipstation_ssl_encrypted)
    end
  end

end
