require 'spec_helper'
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
    instance_double(Aws::S3::Presigner, presigned_url: 'presigned-url')
  end

  describe '#handle' do
    subject { handler.handle(sns_client: sns_client, s3_signer: s3_signer) }

    context 'on INSERT or UPDATE event' do
      context 'when record status is pending' do
        let(:env) do
          HashWithIndifferentAccess.new(
            params: {
              _eventName: 'INSERT',
              id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
              input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
              merge_fields: {
                content: 'The best things in life are not things'
              },
              pipeline: [],
              status: 'pending'
            }
          )
        end

        let(:message) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: :pending,
            input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
            merge_fields: {
              content: 'The best things in life are not things',
            },
            pipeline: [],
          }
        end

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('STATE_CHANGED_TOPIC') { 'state-changed-topic' }
        end

        it_behaves_like 'it respects contract with consumer lambda function', 'dispatchr'

        it 'sends an SNS message to STATE_CHANGED_TOPIC' do
          expect(sns_client).to receive(:publish)
            .with(topic_arn: 'state-changed-topic', message: JSON.generate(message))
          subject
        end
      end

      context 'when record status is success' do
        let(:env) do
          HashWithIndifferentAccess.new(
            params: {
              _eventName: 'MODIFY',
              id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
              input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
              merge_fields: {
                content: 'The best things in life are not things'
              },
              document: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generated-pdf/document.pdf',
              pipeline: [],
              status: 'success'
            }
          )
        end

        let(:message) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: :success,
            document_url: 'presigned-url',
          }
        end

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DOCUMENT_CREATED_TOPIC') { 'document-created-topic' }
        end

        let(:document_created_schema) { Pathname.new('document_created_schema.json') }

        it 'respects contract with consumer' do
          expect(JSONSchemer.schema(document_created_schema).valid?(message.as_json)).to be_truthy
        end

        it 'sends an SNS message to DOCUMENT_CREATED_TOPIC' do
          expect(sns_client).to receive(:publish)
            .with(topic_arn: 'document-created-topic', message: JSON.generate(message))
          subject
        end
      end

      context 'when record status is failure' do
        let(:env) do
          HashWithIndifferentAccess.new(
            params: {
              _eventName: 'MODIFY',
              id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
              input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
              merge_fields: {
                content: 'The best things in life are not things'
              },
              pipeline: [],
              status: 'failure'
            }
          )
        end

        let(:message) do
          {
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            status: :failure,
          }
        end

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('DOCUMENT_CREATED_TOPIC') { 'document-created-topic' }
        end

        let(:document_created_schema) { Pathname.new('document_created_schema.json') }

        it 'respects contract with consumer' do
          expect(JSONSchemer.schema(document_created_schema).valid?(message.as_json)).to be_truthy
        end

        it 'sends an SNS message to DOCUMENT_CREATED_TOPIC' do
          expect(sns_client).to receive(:publish)
            .with(topic_arn: 'document-created-topic', message: JSON.generate(message))
          subject
        end
      end
    end

    context 'on REMOVE event' do
      let(:env) do
        HashWithIndifferentAccess.new(
          params: {
            _eventName: 'REMOVE',
            id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
            input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generated-pfd/document.pdf',
            merge_fields: {
              content: 'The best things in life are not things'
            },
            pipeline: [],
            status: 'success'
          }
        )
      end

      it 'does nothing' do
        expect(sns_client).not_to receive(:publish)
        subject
      end
    end
  end
end
