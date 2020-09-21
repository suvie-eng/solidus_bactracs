# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

require 'solidus_shipstation/version'
require 'solidus_shipstation/engine'
require 'solidus_shipstation/configuration'
require 'solidus_shipstation/errors'
require 'solidus_shipstation/shipment_notice'

module SolidusShipstation
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
