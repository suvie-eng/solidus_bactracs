RSpec.describe SolidusShipstation::Shipment::PendingApiSyncQuery do
  describe '.apply' do
    context 'when dealing with unsynced shipments' do
      it 'returns the shipments for orders that were recently updated' do
        stub_configuration(api_sync_threshold: 5.minutes)

        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.order.update_columns(updated_at: 4.minutes.ago)
        end
        create(:order_ready_to_ship).shipments.first.tap do |s|
          s.order.update_columns(updated_at: 6.minutes.ago)
        end

        expect(described_class.apply(Spree::Shipment.all)).to match_array([shipment])
      end
    end

    context 'when dealing with synced shipments' do
      it 'returns the shipments that were recently synced' do
        stub_configuration(api_sync_threshold: 5.minutes)

        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(shipstation_synced_at: 4.minutes.ago)
        end
        create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(shipstation_synced_at: 6.minutes.ago)
        end

        expect(described_class.apply(Spree::Shipment.all)).to match_array([shipment])
      end
    end
  end
end
