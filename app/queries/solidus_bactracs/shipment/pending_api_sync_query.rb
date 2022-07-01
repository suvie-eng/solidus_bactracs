# frozen_string_literal: true

module SolidusBactracs
  module Shipment
    class PendingApiSyncQuery
      SQLITE_CONDITION = <<~SQL.squish
        (
          spree_shipments.bactracs_synced_at IS NULL
        ) AND ((JULIANDAY(CURRENT_TIMESTAMP) - JULIANDAY(spree_orders.updated_at)) * 86400.0) < :threshold
      SQL

      POSTGRES_CONDITION = <<~SQL.squish
        (
          spree_shipments.bactracs_synced_at IS NULL
        ) AND (EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - spree_orders.updated_at))) < :threshold
      SQL

      MYSQL2_CONDITION = <<~SQL.squish
        (
          spree_shipments.bactracs_synced_at IS NULL
        ) AND (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(spree_orders.updated_at)) < :threshold
      SQL

      class << self
        def apply(scope)
          scope
            .joins(:order)
            .merge(::Spree::Order.complete)
            .where(condition_for_adapter, threshold: SolidusBactracs.config.api_sync_threshold / 1.second)
        end

        private

        def condition_for_adapter
          db_adapter = ActiveRecord::Base.connection.adapter_name.downcase

          case db_adapter
          when /sqlite/
            SQLITE_CONDITION
          when /postgres/
            POSTGRES_CONDITION
          when /mysql2/
            MYSQL2_CONDITION
          else
            fail "Bactracs API sync not supported for DB adapter #{db_adapter}!"
          end
        end
      end
    end
  end
end
