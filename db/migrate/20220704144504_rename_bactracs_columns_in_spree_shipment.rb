# frozen_string_literal: true

class RenameBactracsColumnsInSpreeShipment < ActiveRecord::Migration[5.2]
  def change
    if ( ActiveRecord::Base.connection.column_exists?(:spree_shipments, :backtracs_sync_verified_at) &&
        !ActiveRecord::Base.connection.column_exists?(:spree_shipments, :bactracs_sync_verified_at))
      rename_column :spree_shipments, :backtracs_sync_verified_at, :bactracs_sync_verified_at
    end
  end
end
