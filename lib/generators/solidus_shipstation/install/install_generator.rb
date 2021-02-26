# frozen_string_literal: true

module SolidusShipstation
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false
      source_root File.expand_path('templates', __dir__)

      def copy_initializer
        copy_file 'initializer.rb', 'config/initializers/solidus_shipstation.rb', skip: true
      end

      def add_migrations
        run 'bin/rails railties:install:migrations FROM=solidus_shipstation'
      end
    end
  end
end
