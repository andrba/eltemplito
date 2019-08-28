require 'spec_helper'

RSpec.describe 'RenderingLambdaFunction', integration: true do
  let(:cloudformation) { Aws::CloudFormation::Client.new }
  let(:stack_resources) { cloudformation.describe_stack_resources(stack_name: ENV['ELTEMPLITO_STACK_NAME']).stack_resources }

  let(:event_source_queue_url) { stack_resources.find { |resource| resource.logical_resource_id == 'RenderingSQSQueue' }.physical_resource_id }
  let(:pdf_generation_queue_url) { stack_resources.find { |resource| resource.logical_resource_id == 'PDFGenerationSQSQueue' }.physical_resource_id }
  let(:s3_bucket_name) {  stack_resources.find { |resource| resource.logical_resource_id == 'S3Bucket' }.physical_resource_id }

  let(:environment) {
    {
      'RendererLambdaFunction' => {
        'S3_BUCKET' => s3_bucket_name,
        'EVENT_SOURCE_QUEUE_URL' => event_source_queue_url,
        'PDF_GENERATION_QUEUE_URL' => pdf_generation_queue_url
      }
    }
  }

  let(:event_body) {
    JSON.generate(
      template_url: "https://github.com/senny/sablon/blob/master/test/fixtures/insertion_template.docx?raw=true",
      merge_fields: {
        content: "The best things in life are not things"
      }
    )
  }

  let(:event) {
    {
      "Records" => [
        {
          "messageId" => "059f36b4-87a3-44ab-83d2-661975830a7d",
          "receiptHandle" => "AQEBwJnKyrHigUMZj6rYigCgxlaS3SLy0a...",
          "body" => event_body,
          "attributes" => {
              "ApproximateReceiveCount" => "1",
              "SentTimestamp" => "1545082649183",
              "SenderId" => "AIDAIENQZJOLO23YVJ4VO",
              "ApproximateFirstReceiveTimestamp" => "1545082649185"
          },
          "messageAttributes" => {},
          "md5OfBody" => "098f6bcd4621d373cade4e832627b4f6",
          "eventSource" => "aws:sqs",
          "eventSourceARN" => "arn:aws:sqs:us-east-2:123456789012:my-queue",
          "awsRegion" => ENV['AWS_REGION']
        }
      ]
    }
  }

  around(:all) do |example|
    env_file = Tempfile.new('env')
    env_file.write(JSON.generate(environment))
    env_file.close

    @env_file_path = env_file.path
    example.run
  end

  let(:response) {
    args = ['--env-vars', @env_file_path, '--skip-pull-image', 'RendererLambdaFunction']

    %i[stdout stderr status].zip(
      Open3.capture3("sam local invoke #{args.join(' ')}", stdin_data: JSON.generate(event))
    ).to_h.tap do |resp|
      resp[:stdout] = eval(eval(resp[:stdout]))
    end
  }

  it 'responds successfully' do
    expect(response[:stdout][:successful]).not_to be_empty
    expect(response[:stdout][:failed]).to be_empty
    expect(response[:status].success?).to be_truthy
  end
end
