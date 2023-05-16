# frozen_string_literal: true
require "sidekiq"

RSpec.describe SolidusBactracs::Api::ScheduleShipmentSyncsJob do
  it 'schedules the shipment sync in batches' do
    stub_configuration(api_batch_size: 2)
    shipments = create_list(:shipment, 3)
    relation = instance_double('ActiveRecord::Relation').tap do |r|
      allow(r).to receive(:find_in_batches)
        .with(batch_size: 2)
        .and_yield(shipments[0..1])
        .and_yield([shipments.last])
    end
    allow(SolidusBactracs::Shipment::PendingApiSyncQuery).to receive(:apply)
      .and_return(relation)

    described_class.new.perform

    expect(SolidusBactracs::Api::SyncShipmentsJob).to have_been_enqueued.with(shipments[0..1])
    expect(SolidusBactracs::Api::SyncShipmentsJob).to have_been_enqueued.with([shipments.last])
  end

  it 'reports any errors to the handler' do
    error_handler = instance_spy('Proc')
    stub_configuration(error_handler: error_handler)
    error = RuntimeError.new('Something went wrong')
    allow(SolidusBactracs::Shipment::PendingApiSyncQuery).to receive(:apply).and_raise(error)

    described_class.new.perform

    expect(error_handler).to have_received(:call).with(error, {})
  end
end
