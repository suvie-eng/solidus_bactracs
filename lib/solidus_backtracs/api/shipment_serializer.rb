# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ShipmentSerializer

      def initialize(shipment:)
        @shipment = shipment
        @config = SolidusBacktracs.config
        @property_id = ::Spree::Property.find_by(name: SolidusBacktracs.config.default_property_name)&.id
      end

      def call(sguid: nil)
        order = @shipment.order
        user = @shipment.user

        xml = Builder::XmlMarkup.new 
        xml.instruct!(:xml, :encoding => "UTF-8")

        xml.soap(:Envelope, {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"}) do
          xml.soap :Body do
            xml.CreateNew({"xmlns" => "http://bactracs.andlor.com/rmaservice"}) do
              xml.sGuid                       sguid
              xml.NewRMA {
                xml.RMANumber                 @shipment.number
                xml.RMATypeName               @config.default_rma_type
                xml.RMASubTypeName            
                xml.CustomerRef               
                xml.InboundShippingPriority   
                xml.InboundTrackingNumber     @shipment.tracking

                xml.Ship {
                  xml.Carrier                 @config.default_carrier
                  xml.ShipMethod              @config.default_ship_method
                  xml.ShipDate                @shipment.created_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                  xml.TrackingNumber          @shipment.tracking
                  xml.SerialNumber            @shipment.number
                  xml.Ud1                     
                }
                xml.Customer {
                  SolidusBacktracs::ExportHelper.backtracs_address(xml, order, :ship)
                  SolidusBacktracs::ExportHelper.backtracs_address(xml, order, :bill)
                }
                xml.Rep {
                  xml.Code                    
                  xml.Name                    user.full_name
                  xml.Email                   user.email
                }        

                xml.RMALines {
                  @shipment.line_items.each do |line|
                    product = line.product
                    if product.respond_to?(:assembly?) && product.assembly?
                      product.parts.each do |part|
                        next unless part.product.product_properties.where(property_id: @property_id).present?
                        line_items_xml(xml: xml, line_item: line, variant: part, order: order)
                      end
                    else
                      line_items_xml(xml: xml, line_item: line, variant: line.variant, order: order)
                    end
                  end
                }
                xml.OrderDate     order.completed_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.CreateDate    @shipment.created_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.Status        @config.default_status
                xml.RMAId         @shipment.id
                xml.ClientGuid
              }
            end
          end 
        end
        xml
      end

      def line_items_xml(xml: nil, line_item: nil, variant: nil, order: nil)
        shipment_notice = @shipment.shipment_notice        
        xml.RMALine {
          xml.DFItem                  find_sku_variant(variant)
          xml.DFModelNum              find_sku_variant(variant)
          xml.DFCategory              
          xml.DFCategoryDescription   
          xml.DFQuantity              line_item.quantity
          xml.DFUnitPrice             line_item.price
          xml.DFSerialNumbers         
          xml.Ud1s                    
          xml.CurrentWarranties       
          xml.DFComments              
          xml.DFStatus                @shipment.state
          xml.PurchaseDate            order.completed_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
          xml.ServiceProvider         shipment_notice&.service
          xml.WarrantyRepair          
          xml.RMALineTest             
          xml.InboundShipWeight       variant.weight.to_f
          xml.RPLocation              @config.default_rp_location
        } 
      end

      def find_sku_variant(variant)
        @config.sku_map[variant.sku].present? ? @config.sku_map[variant.sku] : variant.sku
      end
    end
  end
end
