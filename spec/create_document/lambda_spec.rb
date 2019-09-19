require 'spec_helper'
require 'support/shared_examples_for_contract_testing'
require 'create_document/lambda'

RSpec.describe CreateDocument::Handler do
  let(:env) do
    {
      'params' => {
        'file_url' => 'https://path.to/template.docx',
        'output_format' => 'pdf',
        'merge_fields' => {
          'content' => 'The best things in life are not things'
        }
      },
      'context' => {
        'requestId' => '77880a9c-1822-4205-abc2-4bf39ecc9f83'
      }
    }
  end

  let(:handler) { described_class.new(env) }

  let(:s3_client) do
    Aws::S3::Client.new(stub_responses: true).tap do |s3|
      s3.stub_responses(:put_object, {})
    end
  end

  let(:document_repository) { class_double(DocumentRepository, create: true) }

  describe '#handle' do
    subject { handler.handle(s3_client: s3_client, document_repository: document_repository) }

    context 'when template file can be downloaded from file_url' do
      let!(:tempfile) { File.open(File.join(__dir__, '../', 'fixtures', 'template.docx')) }
      let(:message) do
        {
          id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
          input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
          merge_fields: {
            'content' => 'The best things in life are not things',
          },
          pipeline: [Pipeline::RENDER_TEMPLATE, Pipeline::GENERATE_PDF],
          status: :pending
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('S3_BUCKET') { 'eltemplito-test' }
        allow(tempfile).to receive(:original_filename) { 'template.docx' }
        allow(Down).to receive(:download) { tempfile }
      end

      after { tempfile.close }

      it_behaves_like 'it respects contract with consumer lambda function', 'listen_document_stream'

      it 'returns 202' do
        expect(document_repository).to receive(:create).with(message)
        expect(subject).to eq([202, { id: '77880a9c-1822-4205-abc2-4bf39ecc9f83', status: :pending }])
      end
    end

    context 'when template file can not be downloaded from file_url' do
      before do
        allow(Down).to receive(:download).and_raise(Down::Error, 'error message')
      end

      it 'returns 422' do
        expect(subject).to eq(
          [422, { id: '77880a9c-1822-4205-abc2-4bf39ecc9f83', status: :error, message: 'error message' }]
        )
      end
    end
  end
end
