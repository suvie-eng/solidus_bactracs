RSpec.describe SolidusShipstation::Api::Client do
  describe '.from_config' do
    it 'generates a client from the configuration' do
      request_runner = instance_double('SolidusShipstation::Api::RequestRunner')
      allow(SolidusShipstation::Api::RequestRunner).to receive(:from_config)
        .and_return(request_runner)

      client = described_class.from_config

      expect(client).to have_attributes(request_runner: request_runner)
    end
  end

  describe '#bulk_create_orders' do
    it 'calls the bulk order creation endpoint' do
      request_runner = instance_spy('SolidusShipstation::Api::RequestRunner')
      client = described_class.new(request_runner: request_runner)
      shipment = build_stubbed(:shipment)
      serialized_shipment = { 'key' => 'value' }
      allow(SolidusShipstation::Api::Serializer).to receive(:serialize_shipment)
        .and_return(serialized_shipment)

      client.bulk_create_orders([shipment])

      expect(request_runner).to have_received(:call).with(
        :post,
        '/orders/createorders',
        [serialized_shipment],
      )
    end
  end
end
