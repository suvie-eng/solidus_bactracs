RSpec.describe SolidusShipstation::Api::Client do
  describe '.from_config' do
    it 'generates a client from the configuration' do
      request_runner = instance_double('SolidusShipstation::Api::RequestRunner')
      error_handler = instance_spy('Proc')
      allow(SolidusShipstation::Api::RequestRunner).to receive(:from_config).and_return(request_runner)
      allow(SolidusShipstation.config).to receive(:error_handler).and_return(error_handler)

      client = described_class.from_config

      expect(client).to have_attributes(
        request_runner: request_runner,
        error_handler: error_handler,
      )
    end
  end

  describe '#bulk_create_orders' do
    it 'calls the bulk order creation endpoint' do
      request_runner = instance_spy('SolidusShipstation::Api::RequestRunner')
      client = build_client(request_runner: request_runner)
      shipment = build_stubbed(:shipment)
      serialized_shipment = { 'key' => 'value' }
      stub_serializer(shipment, serialized_shipment)

      client.bulk_create_orders([shipment])

      expect(request_runner).to have_received(:call).with(
        :post,
        '/orders/createorders',
        [serialized_shipment],
      )
    end

    it 'does not fail for serialization errors' do
      request_runner = instance_spy('SolidusShipstation::Api::RequestRunner')
      client = build_client(request_runner: request_runner)
      successful_shipment = build_stubbed(:shipment)
      failing_shipment = build_stubbed(:shipment)
      error = RuntimeError.new('Failed to serialize shipment!')
      serialized_shipment = { 'key' => 'value' }
        stub_serializer(successful_shipment, serialized_shipment)
        stub_serializer(failing_shipment, error)

      client.bulk_create_orders([failing_shipment, successful_shipment])

      expect(request_runner).to have_received(:call).with(
        :post,
        '/orders/createorders',
        [serialized_shipment],
      )
    end

    it 'reports any serialization errors to the error handler' do
      error_handler = instance_spy('Proc')
      client = build_client(error_handler: error_handler)
      shipment = build_stubbed(:shipment)
      error = RuntimeError.new('Failed to serialize shipment!')
      stub_serializer(shipment, error)

      client.bulk_create_orders([shipment])

      expect(error_handler).to have_received(:call).with(error, shipment: shipment)
    end

    it 'skips the API call if all shipments failed serialization' do
      request_runner = instance_spy('SolidusShipstation::Api::RequestRunner')
      client = build_client(request_runner: request_runner)
      failing_shipment = build_stubbed(:shipment)
      stub_serializer(failing_shipment, RuntimeError.new('Failed to serialize shipment!'))

      client.bulk_create_orders([failing_shipment])

      expect(request_runner).not_to have_received(:call)
    end
  end

  private

  def build_client(options = {})
    described_class.new({
      request_runner: instance_spy('SolidusShipstation::Api::RequestRunner'),
      error_handler: instance_spy('Proc'),
    }.merge(options))
  end

  def stub_serializer(shipment, result_or_error)
    stub = allow(SolidusShipstation::Api::Serializer).to(receive(:serialize_shipment).with(shipment))

    if result_or_error.is_a?(Hash)
      stub.and_return(result_or_error)
    else
      stub.and_raise(result_or_error)
    end
  end
end
