require 'spec_helper'

include Spree

describe Spree::ShipmentNotice do
  let(:order_number) { 'S12345' }
  let(:tracking_number) { '1Z1231234' }
  let(:notice) do
    ShipmentNotice.new(order_number:    order_number,
                       tracking_number: tracking_number)
  end

  context 'capture at notification is active' do
    let(:order) { FactoryGirl.create(:completed_order_with_pending_payment) }
    let(:payment) { order.payments.first }
    let(:shipment) { order.shipments.first }
    let(:notice) do
      ShipmentNotice.new(order_number:    shipment.number,
                         tracking_number: tracking_number)
    end

    before do
      Spree::Config.shipstation_capture_at_notification = true
      expect(payment).to be_pending
      expect(shipment).to be_pending
    end

    context 'successful capture' do
      it 'payments are completed' do
        expect(notice.apply).to eq(true)
        expect(shipment.reload).to be_shipped
        expect(payment.reload).to be_completed
        expect(order.reload).to be_paid
      end
    end

    context 'capture fails' do
      before do
        expect_any_instance_of(Payment).to receive(:capture!).and_raise(Spree::Core::GatewayError)
      end

      it "doesn't ship the shipment" do
        expect(notice.apply).to eq(false)
        expect(shipment.reload).to_not be_shipped
        expect(payment.reload).to_not be_completed
        expect(order.reload).to_not be_paid
      end
    end
  end

  context '#apply' do
    context 'shipment found' do
      let(:order) { instance_double(Order, paid?: true) }
      let(:shipment) { instance_double(Shipment, order: order, shipped?: false, pending?: false) }

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

      context 'order is not paid' do
        before do
          expect(order).to receive(:paid?).and_return(false)
        end

        context 'capture at notification is not active' do
          before do
            Spree::Config.shipstation_capture_at_notification = false
          end

          it 'payments are not captured' do
            expect(notice).to_not receive(:process_payments!)
            expect(order).to receive_message_chain(:errors, :full_messages).and_return(["woops"])
            expect(notice.apply).to eq(false)
            expect(notice.error).to be_present
          end
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

    context 'shipment already shipped' do
      let(:order) { FactoryGirl.create(:order_ready_to_ship) }
      let(:shipment) { order.shipments.first }

      before do
        shipment.update_attribute(:number, order_number)
      end

      it 'updates #tracking and returns true' do
        expect(notice.apply).to eq(true)
        expect(shipment.reload.tracking).to eq(tracking_number)
      end

      it 'does not update #state' do
        expect { notice.apply }.to_not change { shipment.state }
      end
    end
  end
end
