# frozen_string_literal: true

module SolidusBactracs
  module Api
    class ScheduleTradeUpShipmentSyncsJob < SolidusBactracs::Api::ScheduleShipmentSyncsJob
      queue_as :default

      def perform
        shipments = query_shipments
        Rails.logger.info("#{self.class.name} - #{shipments.count} shipments to sync to Bactracs")

        shipments.find_in_batches(batch_size: SolidusBactracs.config.api_batch_size) do |batch|
          SyncShipmentsJob.perform_later(batch.to_a, true)
        end
      rescue StandardError => e
        SolidusBactracs.config.error_handler.call(e, {})
      end

      def query_shipments
        shipments = ::Spree::Shipment
                      .joins(order: [user: [:trade_up_flow]])
                      .where("account_flows.data->>'form_response_received_at' <= ? AND account_flows.data->>'packaging' = ?", 6.hours.ago, "true")
                      .distinct
      end
    end
  end
end
