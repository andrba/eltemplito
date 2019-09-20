require 'support/shared_examples_for_contract_testing'
require 'listen_document_stream/lambda'

RSpec.describe ListenDocumentStream::Handler do
  let(:handler) { described_class.new(env) }

  let(:sns_client) do
    Aws::SNS::Client.new(stub_responses: true).tap do |sns|
      sns.stub_responses(:publish, {})
    end
  end

  let(:s3_signer) do
    Aws::S3::Presigner.new(stub_responses: true).tap do |s3|
      s3.stub_responses(:presigned_url, {})
    end
  end

  describe '#handle' do
    subject { handler.handle(sns_client: sns_client, s3_signer: s3_signer) }

    context 'on INSERT or UPDATE event' do
      context 'when record status is pending' do
        it 'sends an SNS message to STATE_CHANGED_TOPIC' do
        end
      end

      context 'when record status is success' do
        it 'sends an SNS message to DOCUMENTS_TOPIC' do
        end
      end

      context 'when record status is failure' do
        it 'sends an SNS message to DOCUMENTS_TOPIC' do
        end
      end
    end

    context 'on REMOVE event' do
      it 'does nothing' do
      end
    end
  end
end
