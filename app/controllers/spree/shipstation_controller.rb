require_dependency 'spree/basic_ssl_authentication'

module Spree

  class ShipstationController < Spree::BaseController

    include Spree::BasicSslAuthentication
    include Spree::DateParamHelper

    protect_from_forgery with: :null_session, only: [:shipnotify]

    def export
      @shipments = Spree::Shipment.exportable
                                  .between(date_param(:start_date),
                                           date_param(:end_date))
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
