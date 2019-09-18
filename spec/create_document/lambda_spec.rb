require 'spec_helper'
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

    context 'when file_url exists' do
      let!(:tempfile) { File.open(File.join(__dir__, '../', 'fixtures', 'template.docx')) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('S3_BUCKET') { 'eltemplito-test' }
        allow(tempfile).to receive(:original_filename) { 'template.docx' }
        allow(Down).to receive(:download) { tempfile }
      end

      after { tempfile.close }

      it 'returns 202' do
        expect(subject).to eq([202, { id: nil, status: 'pending' }])
      end
    end
  end
end
