# NOTE: This migration is only required if you use the API integration strategy.
# If you're using the XML file instead, you can safely skip these columns.

class AddBactracsApiSyncFields < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :bactracs_synced_at, :datetime
  end
end
