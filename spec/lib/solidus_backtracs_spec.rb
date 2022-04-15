require 'spec_helper'

RSpec.describe SolidusBacktracs do
  describe 'VERSION' do
    it 'is defined' do
      expect(SolidusBacktracs::VERSION).to be_present
    end
  end
end
