require 'spec_helper'

include Spree

describe Spree::ShipmentNotice do
  let(:order_number) { 'S12345' }
  let(:tracking_number) { '1Z1231234' }
  let(:notice) do
    ShipmentNotice.new(order_number:    order_number,
                       tracking_number: tracking_number)
  end

  context '#apply' do
    context 'shipment found' do
      let(:shipment) { double(Shipment, shipped?: false) }

      before do
        Spree::Config.shipstation_number = :shipm # if you prefer to send notifications via shipstationent
        Shipment.should_receive(:find_by_number).with(order_number).and_return(shipment)
        shipment.should_receive(:update_attribute).with(:tracking, tracking_number)
      end

      context 'transition succeeds' do
        before do
          shipment.stub_chain(:reload, :update_attribute).with(:state, 'shipped')
          shipment.stub_chain(:inventory_units, :each)
          shipment.should_receive(:touch).with(:shipped_at)
        end

        specify { notice.apply.should eq(true) }
      end

      context 'transition fails' do
        before do
          shipment.stub_chain(:reload, :update_attribute)
                  .with(:state, 'shipped')
                  .and_raise('oopsie')
          @result = notice.apply
        end

        specify { @result.should eq(false) }
        specify { notice.error.should_not be_blank }
      end
    end

    context 'using order number instead of shipment number' do
      let(:order) { create(:order, number: order_number) }
      let!(:shipment) { create(:shipment, order: order) }

      before { Spree::Config.shipstation_number = :order }

      it 'successfully updates the shipment', :aggregate_failures do
        expect(notice.apply).to eq(true)
        expect(notice.error).to_not be_present
        expect(shipment.reload.state).to eq('shipped')
        expect(shipment.tracking).to eq(tracking_number)
      end
    end

    context 'shipment not found' do
      before do
        Spree::Config.shipstation_number = :shipment
        Shipment.should_receive(:find_by_number).with('S12345').and_return(nil)
      end

      it '#apply returns false and sets @error' do
        expect(notice.apply).to eq(false)
        expect(notice.error).to be_present
      end
    end

    context 'shipment already shipped' do
      let(:shipment) { double(Shipment, shipped?: true) }

      before do
        Spree::Config.shipstation_number = :shipment
        Shipment.should_receive(:find_by_number).with('S12345').and_return(shipment)
        shipment.should_receive(:update_attribute).with(:tracking, '1Z1231234')
      end

      specify { notice.apply.should eq(true) }
    end
  end
end
