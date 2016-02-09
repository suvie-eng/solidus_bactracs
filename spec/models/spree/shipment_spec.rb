require 'spec_helper'
require 'timecop'

describe Spree::Shipment do
  context 'shipment_decorator methods' do
    describe '.between' do
      let(:now) { Time.now.utc }

      let!(:order_1) { create(:order) }
      let!(:order_2) { create(:order) }
      let!(:order_3) { create(:order) }
      let!(:yesterday) { create_shipment(order: order_2) }
      let!(:tomorrow) { create_shipment(order: order_2) }
      let!(:old_shipment_recent_order_update) { create_shipment(created_at: now - 1.week, order: order_3) }
      let!(:active_1) { create_shipment }
      let!(:active_2) { create_shipment }
      let(:query) { Spree::Shipment.between(now - 1.hour, now + 1.hour) }

      # Use Timecop set #updated_at at specific times rather than manually settting them
      #   as ActiveRecord will automatically set #updated_at timestamps even when attempting to
      #   override them for Spree::Order instances
      before do
        Timecop.freeze(now - 1.day) do
          order_1.touch
          yesterday.touch
        end

        Timecop.freeze(now + 1.day) do
          order_2.touch
          tomorrow.touch
        end

        Timecop.freeze(now - 1.week) do
          order_3.touch
        end
      end

      it 'returns shipments based on shipments/orders updated_at within the given time range', :aggregate_failures do
        expect(query.count).to eq(3)
        expect(query).to match_array([old_shipment_recent_order_update, active_1, active_2])
      end
    end

    describe '.exportable' do
      let!(:pending) { create_shipment(state: 'pending') }
      let!(:ready)   { create_shipment(state: 'ready')   }
      let!(:shipped) { create_shipment(state: 'shipped') }

      let(:query) { Spree::Shipment.exportable }

      it 'should have the expected shipment instances', :aggregate_failures do
        expect(query.count).to eq(2)
        expect(query).to eq([ready, shipped])
        expect(query).to_not include(pending)
      end
    end
  end
end
