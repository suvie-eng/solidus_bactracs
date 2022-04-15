# frozen_string_literal: true

require 'builder'

module SolidusBacktracs
  module ExportHelper
    DATE_FORMAT = '%m/%d/%Y %H:%M'
    BACTRACS_DATE_FORMAT = '%Y-%m-%dT%H:%M:%S'

    # rubocop:disable all
    def self.address(xml, order, type)
      name = "#{type.to_s.titleize}To"
      address = order.send("#{type}_address")

      xml.__send__(name) {
        xml.Name         address.respond_to?(:name) ? address.name : address.full_name
        xml.Company      address.company

        if type == :ship
          xml.Address1   address.address1
          xml.Address2   address.address2
          xml.City       address.city
          xml.State      address.state ? address.state.abbr : address.state_name
          xml.PostalCode address.zipcode
          xml.Country    address.country.iso
        end

        xml.Phone        address.phone
      }
    end

    def self.backtracs_address(xml, order, type)
      name = "#{type.to_s.titleize}To"
      address = order.send("#{type}_address")

      xml.__send__(name) {
        xml.CompanyName   address.company ? address.company : address.name
        xml.Contact       address.name
        xml.ContactEmail  order.email
        xml.Address1      address.address1
        xml.Address2      address.address2
        xml.City          address.city
        xml.State         address.state ? address.state.abbr : address.state_name
        xml.Zip           address.zipcode
        xml.Phone         address.phone
        xml.PhoneAlt      address.phone
        xml.Country       address.country.iso
      }
    end    
    # rubocop:enable all
  end
end
