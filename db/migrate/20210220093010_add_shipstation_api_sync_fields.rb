# NOTE: This migration is only required if you use the API integration strategy.
# If you're using the XML file instead, you can safely skip these columns.

class AddShipstationApiSyncFields < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :shipstation_synced_at, :datetime
    add_column :spree_shipments, :shipstation_order_id, :string
  end
end
