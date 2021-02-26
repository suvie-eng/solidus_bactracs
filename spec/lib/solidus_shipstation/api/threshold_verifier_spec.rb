RSpec.describe SolidusShipstation::Api::ThresholdVerifier do
  context "when the shipment's order was completed and not cancelled" do
    context 'when the shipment was never synced with ShipStation yet' do
      it 'returns true when the shipment was never synced with ShipStation yet' do
        shipment = create(:order_ready_to_ship).shipments.first

        expect(described_class.call(shipment)).to eq(true)
      end

      it 'returns false when the shipment was created too far in the past' do
        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(created_at: 1.year.ago)
        end

        expect(described_class.call(shipment)).to eq(false)
      end
    end

    context 'when the shipment was already synced with ShipStation' do
      it 'returns true when the shipment is pending a ShipStation re-sync' do
        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(shipstation_synced_at: 5.minutes.ago, updated_at: Time.zone.now)
        end

        expect(described_class.call(shipment)).to eq(true)
      end

      it 'returns false when the shipment is up-to-date in ShipStation' do
        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(shipstation_synced_at: 5.minutes.ago, updated_at: 6.minutes.ago)
        end

        expect(described_class.call(shipment)).to eq(false)
      end

      it 'returns false when the shipment was updated too far in the past' do
        shipment = create(:order_ready_to_ship).shipments.first.tap do |s|
          s.update_columns(shipstation_synced_at: 5.minutes.ago, updated_at: 1.year.ago)
        end

        expect(described_class.call(shipment)).to eq(false)
      end
    end
  end

  context "when the shipment's order was not completed" do
    it 'returns false' do
      shipment = create(:shipment)

      expect(described_class.call(shipment)).to eq(false)
    end
  end
end
