require 'spec_helper'
require 'support/shared_examples_for_contract_testing'
require 'pipeline'
require 'dispatchr/lambda'

RSpec.describe Dispatchr::Handler do
  let(:handler) { described_class.new(env) }

  let(:lambda_client) do
    Aws::Lambda::Client.new(stub_responses: true).tap do |lamb|
      lamb.stub_responses(:invoke_async, {})
    end
  end

  let(:document_repository) { class_double(DocumentRepository, update: true) }

  describe '#handle' do
    subject { handler.handle(lambda_client: lambda_client, document_repository: document_repository) }

    context 'when pipeline is empty' do
      let(:env) do
        {
          'params' => {
            'id' => '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            'input_file' => '77880a9c-1822-4205-abc2-4bf39ecc9f83/generate-pdf/document.pdf',
            'merge_fields' => {
              'content' => 'The best things in life are not things'
            },
            'pipeline' => [],
          }
        }
      end

      let(:message) do
        {
          document: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generate-pdf/document.pdf',
          status: :success
        }
      end

      it_behaves_like 'it respects contract with consumer lambda function', 'listen_document_stream'

      it 'updates message in db' do
        expect(document_repository).to receive(:update).with('77880a9c-1822-4205-abc2-4bf39ecc9f83', message)
        subject
      end
    end

    context 'when the next step in pipeline is rendering template' do
      let(:env) do
        {
          'params' => {
            'id' => '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            'input_file' => '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
            'merge_fields' => {
              'content' => 'The best things in life are not things'
            },
            'pipeline' => [Pipeline::RENDER_TEMPLATE],
          }
        }
      end

      let(:message) do
        {
          id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
          input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
          merge_fields: {
            content: 'The best things in life are not things'
          },
          pipeline: []
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('RENDER_TEMPLATE_FUNCTION') { 'render-template-function' }
      end

      it_behaves_like 'it respects contract with consumer lambda function', 'render_template'

      it 'invokes RenderTemplateFunction' do
        expect(lambda_client).to receive(:invoke_async).with(function_name: 'render-template-function', invoke_args: JSON.generate(message))
        subject
      end
    end

    context 'when the next step in pipeline is generating pdf' do
      let(:env) do
        {
          'params' => {
            'id' => '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            'input_file' => '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
            'merge_fields' => {
              'content' => 'The best things in life are not things'
            },
            'pipeline' => [Pipeline::GENERATE_PDF],
          }
        }
      end

      let(:message) do
        {
          id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
          input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
          merge_fields: {
            content: 'The best things in life are not things'
          },
          pipeline: []
        }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('GENERATE_PDF_FUNCTION') { 'generate-pdf-function' }
      end

      it_behaves_like 'it respects contract with consumer lambda function', 'generate_pdf'

      it 'invokes GeneratePdfFunction' do
        expect(lambda_client).to receive(:invoke_async).with(function_name: 'generate-pdf-function', invoke_args: JSON.generate(message))
        subject
      end
    end
  end
end
