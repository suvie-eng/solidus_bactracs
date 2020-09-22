# frozen_string_literal: true

module SolidusShipstation
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file 'vendor/assets/javascripts/solidus_shipstation/frontend/all.js', "//= require solidus_shipstation/frontend/solidus_shipstation\n"
        append_file 'vendor/assets/javascripts/solidus_shipstation/backend/all.js', "//= require solidus_shipstation/backend/solidus_shipstation\n"
      end

      def add_stylesheets
        inject_into_file 'vendor/assets/stylesheets/solidus_shipstation/frontend/all.css', " *= require solidus_shipstation/frontend/solidus_shipstation\n", before: %r{\*/}, verbose: true
        inject_into_file 'vendor/assets/stylesheets/solidus_shipstation/backend/all.css', " *= require solidus_shipstation/backend/solidus_shipstation\n", before: %r{\*/}, verbose: true
      end

      def add_migrations
        run 'bin/rails railties:install:migrations FROM=solidus_shipstation'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
        if run_migrations
          run 'bin/rails db:migrate'
        else
          puts 'Skipping bin/rails db:migrate, don\'t forget to run it!' # rubocop:disable Rails/Output
        end
      end
    end
  end
end
