# frozen_string_literal: true

module SolidusShipstation
  class Configuration
    attr_accessor :username, :password, :weight_units, :ssl_encrypted, :capture_at_notification
  end
end
