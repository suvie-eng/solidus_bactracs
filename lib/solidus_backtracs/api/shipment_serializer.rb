# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ShipmentSerializer

      def initialize(shipment:)
        @shipment = shipment
      end

      def call(sguid: nil)
        order = @shipment.order
        user = @shipment.user
        shipment_notice = @shipment.shipment_notice

        xml = Builder::XmlMarkup.new 
        xml.instruct!(:xml, :encoding => "UTF-8")

        xml.soap(:Envelope, {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"}) do
          xml.soap :Body do
            xml.CreateNew({"xmlns" => "http://bactracs.andlor.com/rmaservice"}) do
              xml.sGuid                       sguid
              xml.NewRMA {
                xml.RMANumber                 @shipment.number
                xml.RMATypeName               SolidusBacktracs.config.default_rma_type
                xml.RMASubTypeName            
                xml.CustomerRef               
                xml.InboundShippingPriority   
                xml.InboundTrackingNumber     @shipment.tracking

                xml.Ship {
                  xml.Carrier                 SolidusBacktracs.config.default_carrier
                  xml.ShipMethod              SolidusBacktracs.config.default_ship_method
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
                    variant = line.variant
                    xml.RMALine {
                      xml.DFItem                  find_sku_variant(variant)
                      xml.DFModelNum              find_sku_variant(variant)
                      xml.DFCategory              
                      xml.DFCategoryDescription   
                      xml.DFQuantity              line.quantity
                      xml.DFUnitPrice             line.price
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
                      xml.RPLocation              SolidusBacktracs.config.default_rp_location
                    }
                  end
                }

                xml.OrderDate     order.completed_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.CreateDate    @shipment.created_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.Status        SolidusBacktracs.config.default_status
                xml.RMAId         @shipment.id
                xml.ClientGuid
              }
            end
          end 
        end
        xml
      end

      def find_sku_variant(variant)
        SolidusBacktracs.config.sku_map[variant.sku].present? ? SolidusBacktracs.config.sku_map[variant.sku] : variant.sku
      end
    end
  end
end
