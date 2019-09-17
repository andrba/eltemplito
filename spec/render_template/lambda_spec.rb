require 'spec_helper'
require 'app/render_template/lambda'

RSpec.describe RenderTemplate::Lambda, integration: true do
  subject { described_class.handle(event: event, context: {}) }

  let(:event) { JSON.load('spec/fixtures/render_template.json') }

  before(:all) do
    allow(RenderTemplate::Lambda::S3).to receive(:get_object)
    allow(RenderTemplate::Lambda::S3).to receive(:put_object)
    allow(RenderTemplate::Lambda::SNS).to receive(:publish)
  end

  let(:expected_response) do
    JSON.generage(event.merge('input_file' => 'rendered-template/'
  end

  it 'saves a rendered file to S3' do
    expect(RenderTemplate::Lambda::S3).to receive(:get_object).with
  end

  it 'publishes a message to SNS' do
    expect(RenderTemplate::Lambda::SNS).
      to receive(:publish).
      with(topic_arn: state_changed_topic_name, message: ).
      and_call_original
  end
end
