# frozen_string_literal: true

module Spree
  module DateParamHelper
    DATE_FORMAT = '%m/%d/%Y %H:%M %Z'

    private

    def date_param(name)
      return if params[name].nil?

      Time.strptime(params[name] + ' UTC', DATE_FORMAT)
    end
  end
end
