# frozen_string_literal: true

RSpec.describe SolidusShipstation::Api::ScheduleShipmentSyncsJob do
  it 'schedules the shipment sync in batches' do
    stub_configuration(api_batch_size: 2)
    shipments = create_list(:shipment, 3)
    relation = instance_double('ActiveRecord::Relation').tap do |r|
      allow(r).to receive(:find_in_batches)
        .with(batch_size: 2)
        .and_yield(shipments[0..1])
        .and_yield([shipments.last])
    end
    allow(SolidusShipstation::Shipment::PendingApiSyncQuery).to receive(:apply)
      .and_return(relation)

    described_class.perform_now

    expect(SolidusShipstation::Api::SyncShipmentsJob).to have_been_enqueued.with(shipments[0..1])
    expect(SolidusShipstation::Api::SyncShipmentsJob).to have_been_enqueued.with([shipments.last])
  end
end
