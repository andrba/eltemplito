require 'spec_helper'
require 'middleware/validate_schema'

RSpec.describe ValidateSchema do
  let(:app) { double("app", call: true) }

  describe '#call' do
    subject { described_class.new(app, schema).call(env) }

    let(:env) do
      HashWithIndifferentAccess.new(
        context: {},
        event: {},
        params: params,
      )
    end

    context 'when schema path is defined' do
      let(:schema) { 'document_created_schema.json' }

      context 'when schema is valid' do
        let(:params) do
          {
            id: 'c7979ee4-7424-4659-b787-7879bf1a51d4',
            status: 'success',
            document_url: 'https://path.to/document.pdf'
          }
        end

        it 'passes env to the next middleware' do
          expect(app).to receive(:call)
          subject
        end
      end

      context 'when schema is invalid' do
        let(:params) do
          {
            id: 'c7979ee4-7424-4659-b787-7879bf1a51d4',
            status: 'success'
          }
        end

        it 'raises an exception' do
          expect { subject }.to raise_error(ValidateSchema::SchemaError)
        end
      end
    end

    context 'when schema path is undefined' do
      let(:params) { {} }
      let(:schema) { nil }

      it 'passes env to the next middleware' do
        expect(app).to receive(:call)
        subject
      end
    end
  end
end
