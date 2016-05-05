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
      def create_complete_order
        FactoryGirl.create(:order, state: 'complete', completed_at: Time.now)
      end

      let!(:incomplete_order) { create(:order, state: 'confirm') }
      let!(:incomplete) { create_shipment(state: 'pending',
                                          order: incomplete_order) }
      let!(:pending) { create_shipment(state: 'pending',
                                       order: create_complete_order) }
      let!(:ready)   { create_shipment(state: 'ready',
                                       order: create_complete_order) }
      let!(:shipped) { create_shipment(state: 'shipped',
                                       order: create_complete_order) }
      let!(:canceled) { create_shipment(state: 'canceled',
                                        order: create_complete_order) }

      let(:query) { Spree::Shipment.exportable }

      context 'given capture at notification is inactive' do
        before { Spree::Config.shipstation_capture_at_notification = false }
        it 'should have the expected shipment instances', :aggregate_failures do
          expect(query.count).to eq(1)
          expect(query).to eq([ready])
          expect(query).to_not include(pending)
          expect(query).to_not include(incomplete)
        end
      end

      context 'given capture at notification is active' do
        before { Spree::Config.shipstation_capture_at_notification = true }
        it 'should have the expected shipment instances', :aggregate_failures do
          expect(query.count).to eq(3)
          expect(query).to eq([pending, ready, shipped])
          expect(query).to_not include(incomplete)
        end
      end
    end
  end
end
