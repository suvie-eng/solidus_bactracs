if defined?(Sidekiq)
  class BaseSyncJob
    include Sidekiq::Worker

    sidekiq_options queue: 'default'

    def perform_later(*args)
      perform_async(*args)
    end

    def perform_now(*args)
      perform_sync(*args)
    end
  end
else
  class BaseSyncJob < ApplicationJob

  end
end
