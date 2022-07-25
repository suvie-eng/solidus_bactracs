# frozen_string_literal: true

class BactracsTypoCorrection < ActiveRecord::Migration[5.2]
  def change
    if ( ActiveRecord::Base.connection.column_exists?(:spree_shipments, :backtracs_synced_at) &&
        !ActiveRecord::Base.connection.column_exists?(:spree_shipments, :bactracs_synced_at))
      rename_column :spree_shipments, :backtracs_synced_at, :bactracs_synced_at
    end
  end
end
