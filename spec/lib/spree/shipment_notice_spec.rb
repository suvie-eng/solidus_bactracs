require 'spec_helper'

include Spree

describe Spree::ShipmentNotice do

  def define_shipment_notice(order, tracking_number = '1Z1231234')
    ShipmentNotice.new(order_number: order.shipments.first.number,
                       tracking_number: tracking_number)
  end

  context 'capture at notification is true' do
    before do
      Spree::Config.shipstation_capture_at_notification = true
    end

    context 'successful capture' do
      it 'payments are completed' do
        order = FactoryGirl.create(:completed_order_with_pending_payment)
        notice = define_shipment_notice(order)
        expect(notice.apply).to eq(true)

        order.reload.shipments.each do |shipment|
          expect(shipment).to be_shipped
        end
        order.payments.each do |payment|
          expect(payment.reload).to be_completed
        end
        expect(order).to be_paid
      end
    end

    context 'capture fails' do
      it "doesn't ship the shipment" do
        order = FactoryGirl.create(:completed_order_with_pending_payment)
        notice = define_shipment_notice(order)

        expect_any_instance_of(Payment).to receive(:capture!).and_raise(Spree::Core::GatewayError)
        expect(notice.apply).to eq(false)

        order.reload.shipments.each do |shipment|
          expect(shipment).to_not be_shipped
        end
        order.payments.each do |payment|
          expect(payment.reload).to_not be_completed
        end
        expect(order).to_not be_paid
      end
    end
  end

  context 'capture at notification is false' do
    before do
      Spree::Config.shipstation_capture_at_notification = false
    end

    context 'order is not paid' do
      it "doesn't ship the shipment" do
        order = FactoryGirl.create(:completed_order_with_pending_payment)
        notice = define_shipment_notice(order)

        expect(notice.apply).to eq(false)

        order.reload.shipments.each do |shipment|
          expect(shipment).to_not be_shipped
        end
        order.payments.each do |payment|
          expect(payment.reload).to_not be_completed
        end
        expect(order).to_not be_paid
        expect(notice.error).to be_present
      end
    end
  end

  context '#apply' do
    let(:order_number) { 'S12345' }
    let(:tracking_number) { '1Z1231234' }
    let(:order) { instance_double(Order, paid?: true) }
    let(:shipment) { instance_double(Shipment, order: order, shipped?: false, pending?: false) }
    let(:notice) do
      ShipmentNotice.new(order_number:    order_number,
                         tracking_number: tracking_number)
    end

    context 'shipment found' do
      before do
        expect(Shipment).to receive(:find_by).with(number: order_number).and_return(shipment)
      end

      context 'transition succeeds' do
        before do
          expect(shipment).to receive(:update_attribute).with(:tracking, tracking_number)
          expect(shipment).to receive_message_chain(:reload, :ship!)
          expect(shipment).to receive(:touch).with(:shipped_at)
          expect(order).to receive(:update!)
        end

        it 'returns true' do
          expect(notice.apply).to eq(true)
        end

      end

      context 'transition fails' do
        before do
          expect(shipment).to receive(:update_attribute).with(:tracking, tracking_number)
          expect(shipment).to receive_message_chain(:reload, :ship!).and_raise('oopsie')
          expect(Rails.logger).to receive(:error)
          @result = notice.apply
        end

        it 'returns false and sets @error', :aggregate_failures do
          expect(@result).to eq(false)
          expect(notice.error).to be_present
        end
      end
    end

    context 'shipment not found' do
      before do
        expect(Shipment).to receive(:find_by).with(number: order_number).and_return(nil)
        expect(Rails.logger).to receive(:error)
      end

      it '#apply returns false and sets @error', :aggregate_failures do
        expect(notice.apply).to eq(false)
        expect(notice.error).to be_present
      end
    end
  end

  context 'shipment already shipped' do
    it 'updates #tracking and returns true' do
      tracking_number = 'ZN10110'
      order = FactoryGirl.create(:shipped_order)
      notice = define_shipment_notice(order, tracking_number)

      expect(notice.apply).to eq(true)
      expect(order.reload.shipments.first.tracking).to eq(tracking_number)
    end

    it 'does not update #state' do
      order = FactoryGirl.create(:shipped_order)
      notice = define_shipment_notice(order)
      expect { notice.apply }.to_not change { order.shipments.first.state }
    end
  end
end
