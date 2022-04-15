# frozen_string_literal: true

module SolidusBacktracs
  module Api
    class ShipmentSerializer

      def initialize(shipment:)
        @shipment = shipment
        @order = shipment.order
        @user = shipment.user
        @shipment_notice = shipment.shipment_notice
      end

      def call
        xml = Builder::XmlMarkup.new 
        xml.instruct!(:xml, :encoding => "UTF-8")

        xml.soap(:Envelope, {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/"}) do
          xml.soap :Body do
            xml.CreateNew({"xmlns:xsi" => "http://bactracs.andlor.com/rmaservice"}) do
              xml.sGuid
              xml.NewRMA {
                xml.RMANumber                 @order.number
                xml.RMATypeName               "W"
                xml.RMASubTypeName            
                xml.CustomerRef               
                xml.InboundShippingPriority   
                xml.InboundTrackingNumber     @shipment.tracking

                xml.Ship {
                  xml.Carrier                 @shipment_notice&.carrier
                  xml.ShipMethod              @shipment.shipping_method&.name
                  xml.ShipDate                @shipment.shipped_at&.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                  xml.TrackingNumber          @shipment.tracking
                  xml.SerialNumber            @shipment.number
                  xml.Ud1                     
                }
                xml.Customer {
                  SolidusBacktracs::ExportHelper.backtracs_address(xml, @order, :ship)
                  SolidusBacktracs::ExportHelper.backtracs_address(xml, @order, :bill)
                }
                xml.Rep {
                  xml.Code                    
                  xml.Name                    @user.full_name
                  xml.Email                   @user.email
                }        

                xml.RMALines {
                  @shipment.line_items.each do |line|
                    variant = line.variant
                    xml.RMALine {
                      xml.DFItem                  "S020m"
                      xml.DFModelNum              "S020M"
                      xml.DFCategory              variant.product.name
                      xml.DFCategoryDescription   variant.product.description
                      xml.DFQuantity              line.quantity
                      xml.DFUnitPrice             line.price
                      xml.DFSerialNumbers         @shipment.number
                      xml.Ud1s                    
                      xml.CurrentWarranties       
                      xml.DFComments              
                      xml.DFStatus                @shipment.state
                      xml.PurchaseDate            line.created_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                      xml.ServiceProvider         @shipment_notice&.service
                      xml.WarrantyRepair          
                      xml.RMALineTest             
                      xml.InboundShipWeight       variant.weight.to_f
                      xml.RPLocation              
                    }
                  end
                }

                xml.OrderDate     @order.completed_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.CreateDate    @shipment.created_at.strftime(SolidusBacktracs::ExportHelper::BACTRACS_DATE_FORMAT)
                xml.Status        "OPEN"
                xml.RMAId         @shipment.id
                xml.ClientGuid
              }
            end
          end 
        end
        xml
      end
    end
  end
end
