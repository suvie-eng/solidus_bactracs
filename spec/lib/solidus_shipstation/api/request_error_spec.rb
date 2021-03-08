RSpec.describe SolidusShipstation::Api::RequestError do
  describe '.from_response' do
    it 'extracts the status code, body and headers from the response' do
      response = instance_double(
        'HTTParty::Response',
        code: 500,
        headers: { 'Key' => 'Value' },
        body: '{ "message": "Internal Server Error" }',
      )

      error = described_class.from_response(response)

      expect(error).to have_attributes(
        response_code: 500,
        response_headers: { 'Key' => 'Value' },
        response_body: '{ "message": "Internal Server Error" }',
      )
    end
  end
end
