require 'spree/basic_ssl_authentication'

module Spree

  class ShipstationController < Spree::BaseController

    include Spree::BasicSslAuthentication
    include Spree::DateParamHelper

    # TODO: configure disabling CSRF protection in dev/test
    protect_from_forgery with: :null_session if Rails.env.development?

    def export
      @shipments = Spree::Shipment.between(date_param(:start_date), date_param(:end_date))
                                  .page(params[:page])
                                  .per(50)

      respond_to do |format|
        format.xml { render 'spree/shipstation/export', layout: false }
      end
    end

    # TODO: log when request are succeeding and failing
    def shipnotify
      notice = Spree::ShipmentNotice.new(params)

      if notice.apply
        render(text: 'success')
      else
        render(text: notice.error, status: :bad_request)
      end
    end

  end

end
