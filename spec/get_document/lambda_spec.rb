require 'spec_helper'
require 'support/shared_examples_for_contract_testing'
require 'get_document/lambda'

RSpec.describe GetDocument::Handler do
  let(:env) do
    HashWithIndifferentAccess.new(
      params: {
        id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
      }
    )
  end

  let(:handler) { described_class.new(env) }

  let(:s3_signer) do
    instance_double(Aws::S3::Presigner, presigned_url: 'presigned-url')
  end

  let(:document_repository) { class_double(DocumentRepository, get: item) }

  let(:document_created_schema) { Pathname.new('document_created_schema.json') }

  describe '#handle' do
    subject { handler.handle(document_repository: document_repository, s3_signer: s3_signer) }

    context 'when document exists' do
      context 'when document is generated' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('S3_BUCKET') { 'eltemplito-test' }
        end

        let(:item) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: 'success',
            document: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generated-pdf/template.pdf',
          }
        end

        let(:message) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: 'success',
            document_url: 'presigned-url',
          }
        end

        it 'respects contract with consumer' do
          expect(JSONSchemer.schema(document_created_schema).valid?(message.as_json)).to be_truthy
        end

        it 'returns 200 with a link to the document' do
          expect(document_repository).to receive(:get).with(id: '77880a9c-1822-4205-abc2-4bf39ecc9f83')
          expect(subject).to eq([200, message])
        end
      end

      context 'when document failed to be generated' do
        let(:item) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: 'failure',
          }
        end

        let(:message) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: 'failure',
          }
        end

        it 'returns 200 without a link to the document' do
          expect(document_repository).to receive(:get).with(id: '77880a9c-1822-4205-abc2-4bf39ecc9f83')
          expect(subject).to eq([200, message])
        end
      end
    end

    context 'when document does not exist' do
      let(:item) { nil }

      let(:message) do
        {
          id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
          status: 'failure',
          message: 'Document not found',
        }
      end

      it 'respects contract with consumer' do
        expect(JSONSchemer.schema(document_created_schema).valid?(message.as_json)).to be_truthy
      end

      it 'returns 404' do
        expect(subject).to eq(
          [404, message]
        )
      end
    end
  end
end
