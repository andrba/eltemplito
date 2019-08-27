# Bundler.require(:test, :renderer)

require 'spec_helper'
# require 'functions/renderer/lambda'

RSpec.describe 'Lambda' do

  # let(:cloudformation) { Aws::CloudFormation::Client.new }
  # let(:stack_resources) { cloudformation.describe_stack_resources(stack_name: ENV['ELTEMPLITO_STACK_NAME']).stack_resources }

  # let(:event_source_arn) { stack_resources.find { |resource| resource.logical_resource_id == 'RenderingSQSQueue' }.physical_resource_id }
  # let(:lambdas) { stack_resources.select { |resource| resource.resource_type == 'AWS::Lambda::Function' } }
  # let(:lambda) { }

  # let(:s3_bucket_name) {  stack_resources.find { |resource| resource.logical_resource_id == 'S3Bucket' }.physical_resource_id }
  # let(:even_source_queue_url) {  stack_resources.find { |resource| resource.logical_resource_id == 'RenderingSQSQueue' }.physical_resource_id }

  # before do
  #   allow(ENV).to receive(:[]).with('S3_BUCKET') { s3_bucket_name }
  #   allow(ENV).to receive(:[]).with('EVENT_SOURCE_QUEUE_URL') { even_source_queue_url }
  #   byebug
  # end

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

  let(:response) { system("sam local invoke --skip-pull-image RendererLambdaFunction << #{JSON.generate(event)}") }

  it 'responds successfully' do
    expect(response).to include(statusCode: 200)
  end

  it 'responds with error when an error is raised' do
    expect(response).to include(statusCode: 500)
  end

end
