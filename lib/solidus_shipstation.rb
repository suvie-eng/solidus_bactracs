# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

require 'solidus_shipstation/version'
require 'solidus_shipstation/engine'

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
