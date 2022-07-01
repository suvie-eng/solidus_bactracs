require 'spec_helper'

RSpec.describe SolidusBactracs do
  describe 'VERSION' do
    it 'is defined' do
      expect(SolidusBactracs::VERSION).to be_present
    end
  end
end
