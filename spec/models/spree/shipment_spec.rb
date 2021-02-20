# frozen_string_literal: true

RSpec.describe Spree::Shipment do
  describe '.between' do
    it 'returns shipments whose updated_at falls within the given time range' do
      shipment = create(:shipment) { |s| s.update_column(:updated_at, Time.zone.now) }

      expect(described_class.between(Time.zone.yesterday, Time.zone.tomorrow)).to eq([shipment])
    end

    it "returns shipments whose order's updated_at falls within the given time range" do
      order = create(:order) { |o| o.update_column(:updated_at, Time.zone.now) }
      shipment = create(:shipment, order: order)

      expect(described_class.between(Time.zone.yesterday, Time.zone.tomorrow)).to eq([shipment])
    end

    it 'does not return shipments whose updated_at does not fall within the given time range' do
      create(:shipment) { |s| s.update_column(:updated_at, Time.zone.now) }

      expect(described_class.between(Time.zone.tomorrow, Time.zone.tomorrow + 1.day)).to eq([])
    end

    it "does not return shipments whose order's updated_at falls within the given time range" do
      order = create(:order) { |o| o.update_column(:updated_at, Time.zone.now) }
      create(:shipment, order: order)

      expect(described_class.between(Time.zone.tomorrow, Time.zone.tomorrow + 1.day)).to eq([])
    end
  end

  describe '.exportable' do
    it 'delegates to ExportableQuery' do
      shipment = build_stubbed(:shipment)
      allow(SolidusShipstation::Shipment::ExportableQuery).to receive(:apply).and_return([shipment])

      result = Spree::Deprecation.silence do
        described_class.exportable
      end

      expect(result).to eq([shipment])
    end

    it 'prints a deprecation warning' do
      allow(Spree::Deprecation).to receive(:warn)

      described_class.exportable

      expect(Spree::Deprecation).to have_received(:warn).with(/Spree::Shipment\.exportable/)
    end
  end
end
