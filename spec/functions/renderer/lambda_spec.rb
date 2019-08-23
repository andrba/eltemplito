require 'spec_helper'
require './app/functions/renderer'

RSpec.describe Lambda do
  subject { Lambda }

  context '#handler' do
    let!(:payload) { File.new('./spec/fixtures/events/renderer_event.json').read }
    let!(:context) { {} }
    let!(:event) {
      {
        'headers' => {
          'X-GitHub-Delivery' => '72d3162e-cc78-11e3-81ab-4c9367dc0958',
          'X-GitHub-Event' => 'push'
        },
        'body' => payload
      }
    }

    let(:response) { subject.handler(event: event, context: context) }

    it 'responds successfully' do
      expect(response).to include(statusCode: 200)
    end

    it 'responds with error when an error is raised' do
      expect(response).to include(statusCode: 500)
    end
  end
end
