# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class BatchSyncer
      class << self
        def from_config
          new(
            client: SolidusBacktracs::Api::Client.from_config,
            shipment_matcher: SolidusBacktracs.config.api_shipment_matcher,
          )
        end
      end

      attr_reader :client, :shipment_matcher

      def initialize(client:, shipment_matcher:)
        @client = client
        @shipment_matcher = shipment_matcher
      end

      def call(shipments)
        begin
          response = client.bulk_create_orders(shipments)
        rescue RateLimitedError => e
          ::Spree::Event.fire(
            'solidus_backtracs.api.rate_limited',
            shipments: shipments,
            error: e,
          )

          raise e
        rescue RequestError => e
          ::Spree::Event.fire(
            'solidus_backtracs.api.sync_errored',
            shipments: shipments,
            error: e,
          )

          raise e
        end

        return unless response

        response['results'].each do |backtracs_order|
          shipment = shipment_matcher.call(backtracs_order, shipments)

          unless backtracs_order['success']
            ::Spree::Event.fire(
              'solidus_backtracs.api.sync_failed',
              shipment: shipment,
              payload: backtracs_order,
            )

            next
          end

          shipment.update_columns(
            backtracs_synced_at: Time.zone.now,
            backtracs_order_id: backtracs_order['orderId'],
          )

          ::Spree::Event.fire(
            'solidus_backtracs.api.sync_completed',
            shipment: shipment,
            payload: backtracs_order,
          )
        end
      end
    end
  end
end
