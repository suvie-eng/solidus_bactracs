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

        context 'capture at notification is active' do
          before do
            Spree::Config.shipstation_capture_at_notification = true
          end

          it 'payments are captured' do
            expect(notice).to receive(:ship_it!).and_return(true)
            expect(notice).to receive(:process_payments!).and_return(true)
            expect(notice.apply).to eq(true)
          end

          context 'capture fails' do
            it '#apply returns false and sets @error' do
              expect(order).to receive_message_chain(:errors, :full_messages).and_return(["woops"])
              expect(notice).to receive(:process_payments!).and_return(false)
              expect(notice.apply).to eq(false)
              expect(notice.error).to be_present
            end
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
      let!(:shipment) { create(:shipment, number: order_number, state: 'shipped') }

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
