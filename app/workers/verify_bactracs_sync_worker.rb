# frozen_string_literal: true

class VerifyBactracsSyncWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'default'

  def perform(shipment_id)
    shipment = Spree::Shipment.find_by(id: shipment_id)
    if shipment
      shipment.verify_bactracs_sync!
    end
  end
end
