RSpec.describe SolidusShipstation::Api::ShipmentSerializer do
  describe '#call' do
    it 'serializes the shipment' do
      shipment = create(:order_ready_to_ship).shipments.first

      serializer = described_class.new
      result = serializer.call(shipment)

      expect(result).to be_instance_of(Hash)
    end
  end
end
