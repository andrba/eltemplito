require 'spec_helper'
require 'support/shared_examples_for_contract_testing'
require 'generate_pdf/lambda'

RSpec.describe GeneratePdf::Handler do
  let(:env) do
    HashWithIndifferentAccess.new(
      params: {
        id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
        input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/original/template.docx',
        pipeline: [],
      }
    )
  end

  let(:handler) { described_class.new(env) }

  let(:s3_client) do
    Aws::S3::Client.new(stub_responses: true).tap do |s3|
      s3.stub_responses(:get_object, {})
      s3.stub_responses(:put_object, {})
    end
  end

  let(:sns_client) do
    Aws::SNS::Client.new(stub_responses: true).tap do |sns|
      sns.stub_responses(:publish, {})
    end
  end

  describe '#handle' do
    subject { handler.handle(s3_client: s3_client, sns_client: sns_client) }

    let(:message) do
      {
        id: '77880a9c-1822-4205-abc2-4bf39ecc9f83',
        input_file: '77880a9c-1822-4205-abc2-4bf39ecc9f83/generate-pdf/template.pdf',
        pipeline: [],
      }
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('S3_BUCKET') { 'eltemplito-test' }
      allow(ENV).to receive(:[]).with('STATE_CHANGED_TOPIC') { 'state-changed-topic' }

      FileUtils.cp(File.join('spec', 'fixtures', 'document.pdf'), "/tmp/document.pdf")
      allow(GeneratePdf::Office).to receive(:perform) { "/tmp/document.pdf" }
    end

    it_behaves_like 'it respects contract with consumer lambda function', 'dispatchr'

    it 'sends SNS message' do
      expect(sns_client).to receive(:publish)
        .with(topic_arn: 'state-changed-topic', message: JSON.generate(message))
      subject
    end
  end
end
