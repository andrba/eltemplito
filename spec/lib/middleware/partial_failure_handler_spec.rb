require 'spec_helper'
require 'middleware/partial_failure_handler'

RSpec.describe PartialFailureHandler do
  let(:app) { double("App", call: true) }

  describe '#call' do
    subject { described_class.new(app).call(env) }

    let(:env) do
      HashWithIndifferentAccess.new(
        context: {},
        event: {},
        params: params,
      )
    end

    context 'when params is an array' do
      let(:params) do
        [
          {
            _eventName: 'INSERT',
            _eventId: 'c1362192-c4bb-4c01-999a-210e8281819b',
            id: '0a906bdc-e7b8-4eb6-a906-31de5135b07b'
          },
          'faulty param'
        ]
      end

      before do
        allow(app).to receive(:call).with({
          context: {}, event: {}, params: params.last
        }) { raise StandardError, 'faulty param' }
      end

      it 'passes modified env to the next middleware multiple times' do
        expect(app).to receive(:call).with({
          context: {}, event: {}, params: params.first
        }).once
        expect(app).to receive(:call).with({
          context: {}, event: {}, params: params.last
        }).once.and_raise(StandardError, 'faulty param')

        subject
      end
    end

    context 'when params is not an array' do
      let(:params) { { id: 1 } }

      it 'passes unchanged env to the next middleware' do
        expect(app).to receive(:call).with(env)
        subject
      end
    end
  end
end
