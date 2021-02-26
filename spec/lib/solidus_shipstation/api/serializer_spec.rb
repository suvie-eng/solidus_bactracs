RSpec.describe SolidusShipstation::Api::Serializer do
  describe '.serialize_shipment' do
    it 'serializes the shipment' do
      shipment = create(:order_ready_to_ship).shipments.first

      expect(described_class.serialize_shipment(shipment)).to be_instance_of(Hash)
    end

    it 'merges data from the custom_api_params callable' do
      stub_configuration(custom_api_params: ->(shipment) { { custom_param: shipment.number } })
      shipment = create(:order_ready_to_ship).shipments.first

      result = described_class.serialize_shipment(shipment)

      expect(result).to include(custom_param: shipment.number)
    end
  end
end
