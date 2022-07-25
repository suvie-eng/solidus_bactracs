# frozen_string_literal: true

require "uri"
require "net/http"

class BactracsService
  attr_accessor :token

  def initialize
    @username = SolidusBactracs.configuration.authentication_username
    @password = SolidusBactracs.configuration.authentication_password
    @runner = SolidusBactracs::Api::RequestRunner.new
    # Authenticate account
    authenticate!
  end

  def rma_was_synced?(shipment)
    if @token.present?

      response =
        @runner.call(
          method: :post,
          path: "/webservices/rma/rmaservice.asmx?op=Read",
          params:
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n
              <soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n
              <soap:Body>
                <Read xmlns=\"http://bactracs.andlor.com/rmaservice\">\n
                  <sGuid>#{@token}</sGuid>\n
                  <sRMANumber>#{shipment.number}</sRMANumber>\n
                </Read>\n
              </soap:Body>\n
            </soap:Envelope>"
        )

      if response
        return response.dig("Envelope", "Body", "ReadResponse", "ReadResult", "oRMA").present? rescue false
      end
    end

    return false

  rescue => e
    Rails.logger.error({ message: e.message.to_s, file: "bactracs_service.rb" })

    return false
  end

  private

  def authenticate!

    response =
      @runner.call(
        method: :get,
        path: "/webservices/user/Authentication.asmx/Login?sUserName=#{@username}&sPassword=#{@password}"
      )

    if response.dig("AuthenticationResponse", "Result") == "true"
      @token = response.dig("AuthenticationResponse", "Message")
    end

  rescue => e
    Rails.logger.error({ message: "#{e.message}, file: bactracs_service.rb" })
  end
end
