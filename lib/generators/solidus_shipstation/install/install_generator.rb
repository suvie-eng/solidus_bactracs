# frozen_string_literal: true

module SolidusShipstation
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def generate_shipstation_configuration_file
        copy_file 'config/initializers/solidus_shipstation.rb', 'config/initializers/solidus_shipstation.rb', skip: true
      end
    end
  end
end
