# frozen_string_literal: true
require "uri"
require "net/http"

module SolidusBacktracs
  module Api
    class RequestRunner

      def initialize
        @username = ENV['BACTRACS_USERNAME']
        @password = ENV['BACTRACS_PASSWORD']
        @api_base = ENV['BACTRACS_API_BASE']
      end

      def call
        url = URI("#{@api_base}/webservices/user/Authentication.asmx/Login?sUserName=#{@username}&sPassword=#{@password}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(url)
        response = https.request(request)

        case response.code.to_s
        when /2\d{2}/
          parse_respone(response)
        when '429'
          raise RateLimitedError.from_response(response)
        else
          raise RequestError.from_response(response)
        end
      end

      def parse_respone(response)
        doc = Nokogiri::XML(response.body.squish)
        doc.xpath('//xmlns:AuthenticationResponse//xmlns:Message').inner_text
      end
    end
  end
end
