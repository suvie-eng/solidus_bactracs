# class SolidusBactracs::Api::BaseSyncJob

# end

if defined?(Sidekiq)
  class SolidusBactracs::Api::BaseSyncJob
    include Sidekiq::Worker

    sidekiq_options queue: 'default'

    def self.perform_later(*args)
      perform_async(*args)
    end

    def self.perform_now(*args)
      perform_sync(*args)
    end
  end
else
  class SolidusBactracs::Api::BaseSyncJob < ApplicationJob

  end
end
