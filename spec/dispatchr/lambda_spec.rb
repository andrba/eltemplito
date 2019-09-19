require 'spec_helper'
require 'support/shared_examples_for_contract_testing'
require 'dispatchr/lambda'

RSpec.describe Dispatchr::Handler do
  let(:env) do
    {
      'params' => {
        'id' => '77880a9c-1822-4205-abc2-4bf39ecc9f83',
        'input_file' => '77880a9c-1822-4205-abc2-4bf39ecc9f83/generate-pdf/document.pdf',
        'merge_fields' => {
          'content' => 'The best things in life are not things'
        },
        'pipeline' => pipeline,
      }
    }
  end

  let(:handler) { described_class.new(env) }

  let(:lambda_client) do
    Aws::Lambda::Client.new(stub_responses: true).tap do |s3|
      s3.stub_responses(:invoke, {})
    end
  end

  let(:document_repository) { class_double(DocumentRepository, update: true) }

  describe '#handle' do
    subject { handler.handle(lambda_client: lambda_client, document_repository: document_repository) }

    context 'when pipeline is empty' do
      let(:pipeline) { [] }
      let(:message) do
        {
          document: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generate-pdf/document.pdf',
          status: :success
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('STATE_CHANGED_TOPIC') { 'state-changed-topic' }
      end

      it_behaves_like 'it respects contract with consumer lambda function', 'listen_document_stream'

      it 'updates message in db' do
        expect(document_repository).to receive(:update).with('77880a9c-1822-4205-abc2-4bf39ecc9f83', message)
        subject
      end
    end

    context 'when pipeline is not empty' do
    end
  end
end
