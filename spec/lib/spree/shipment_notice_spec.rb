require 'spec_helper'

include Spree

describe Spree::ShipmentNotice, :focus do
  let(:notice) do
    ShipmentNotice.new(order_number:    'S12345',
                       tracking_number: '1Z1231234')
  end

  context '#apply' do
    context 'shipment found' do
      let(:shipment) { double(Shipment, shipped?: false) }

      before do
        Spree::Config.shipstation_number = :shipment
        Shipment.should_receive(:find_by_number).with('S12345').and_return(shipment)
        shipment.should_receive(:update_attribute).with(:tracking, '1Z1231234')
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
      let(:shipment) { double(Shipment, shipped?: false) }
      let(:order)    { double(Order, shipment: shipment) }

      before do
        Spree::Config.shipstation_number = :order
        Order.should_receive(:find_by_number).with('S12345').and_return(order)
        shipment.should_receive(:update_attribute).with(:tracking, '1Z1231234')
        shipment.stub_chain(:inventory_units, :each)
        shipment.should_receive(:touch).with(:shipped_at)
      end

      context 'transition succeeds' do
        before { shipment.stub_chain(:reload, :update_attribute).with(:state, 'shipped') }

        specify { notice.apply.should eq(true) }
      end
    end

    context 'shipment not found' do
      before do
        Spree::Config.shipstation_number = :shipment
        Shipment.should_receive(:find_by_number).with('S12345').and_return(nil)
        @result = notice.apply
      end

      specify { @result.should eq(false) }
      specify { notice.error.should_not be_blank }
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
