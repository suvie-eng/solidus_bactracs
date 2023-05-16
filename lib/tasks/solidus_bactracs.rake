# frozen_string_literal: true

namespace :solidus_bactracs do
  desc 'Run export jobs to send shipments to Bactracs'
  task export: :environment do
    SolidusBactracs::Api::ScheduleShipmentSyncsJob.perform_async
  end

  desc "Verify bactracs RMA creation"
  task verify_bactracs_sync: :environment do
    Spree::Shipment.not_bactracs_sync_verified.find_each(batch_size: 200) do |shipment|
      # set shipment sync at and bactracs_sync_verified_at attributes by verifying RMA
      shipment.verify_bactracs_sync!
    end
  end
end
