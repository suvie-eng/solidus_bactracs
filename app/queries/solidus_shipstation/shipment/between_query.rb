# frozen_string_literal: true

module SolidusShipstation
  module Shipment
    class BetweenQuery
      def self.apply(scope, from:, to:)
        scope.joins(:order).where(<<~SQL.squish, from: from, to: to)
          (spree_shipments.updated_at > :from AND spree_shipments.updated_at < :to) OR
          (spree_orders.updated_at > :from AND spree_orders.updated_at < :to)
        SQL
      end
    end
  end
end
