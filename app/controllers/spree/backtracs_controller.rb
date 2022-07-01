# frozen_string_literal: true

module Spree
  class BacktracsController < Spree::BaseController
    protect_from_forgery with: :null_session, only: :shipnotify

    before_action :authenticate_backtracs

    def export
      @shipments = SolidusBactracs::Shipment::ExportableQuery.apply(Spree::Shipment.all)
      @shipments = SolidusBactracs::Shipment::BetweenQuery.apply(
        @shipments,
        from: date_param(:start_date),
        to: date_param(:end_date),
      )
      @shipments = @shipments.page(params[:page]).per(50)

      respond_to do |format|
        format.xml { render layout: false }
      end
    end

    def shipnotify
      shipment_notice_class = SolidusBactracs.configuration.shipment_notice_class.constantize
      shipment_notice_class.from_payload(params.to_unsafe_h).apply
      head :ok
    rescue SolidusBactracs::Error => e
      head :bad_request
    end

    private

    def date_param(name)
      return if params[name].blank?

      Time.strptime("#{params[name]} UTC", '%m/%d/%Y %H:%M %Z')
    end

    def authenticate_backtracs
      authenticate_or_request_with_http_basic do |username, password|
        username == SolidusBactracs.configuration.username &&
          password == SolidusBactracs.configuration.password
      end
    end
  end
end
