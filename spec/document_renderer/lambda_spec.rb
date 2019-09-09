# require 'spec_helper'
# require 'aws-sdk-lambda'
# require 'aws-sdk-s3'
# require 'functions/renderer/lambda'

# RSpec.shared_examples 'RendererLambdaFunction' do |response|
#   let(:cloudformation) { Aws::CloudFormation::Client.new }
#   let(:stack_resources) { cloudformation.describe_stack_resources(stack_name: ENV['ELTEMPLITO_STACK_NAME']).stack_resources }
#   let(:s3_bucket_name) {  stack_resources.find { |resource| resource.logical_resource_id == 'S3Bucket' }.physical_resource_id }
#   let(:s3_object_name) { "#{SecureRandom.uuid}-template.docx"}
#   let(:template_s3_object) { Aws::S3::Resource.new.bucket(s3_bucket_name).object(s3_object_name) }

#   let(:template_url) do
#     template_s3_object.upload_file('spec/fixtures/template.docx')
#     template_s3_object.presigned_url(:put)
#   end

#   let(:event_body) do
#     JSON.generate(
#       template_url: template_url,
#       merge_fields: {
#         content: "The best things in life are not things"
#       }
#     )
#   end

#   let(:event) do
#     {
#       "Records" => [
#         {
#           "messageId" => "059f36b4-87a3-44ab-83d2-661975830a7d",
#           "receiptHandle" => "AQEBwJnKyrHigUMZj6rYigCgxlaS3SLy0a...",
#           "body" => event_body,
#           "attributes" => {
#               "ApproximateReceiveCount" => "1",
#               "SentTimestamp" => "1545082649183",
#               "SenderId" => "AIDAIENQZJOLO23YVJ4VO",
#               "ApproximateFirstReceiveTimestamp" => "1545082649185"
#           },
#           "messageAttributes" => {},
#           "md5OfBody" => "098f6bcd4621d373cade4e832627b4f6",
#           "eventSource" => "aws:sqs",
#           "eventSourceARN" => "arn:aws:sqs:us-east-2:123456789012:my-queue",
#           "awsRegion" => "us-east-2"
#         }
#       ]
#     }
#   end

#   it 'responds successfully' do
#     expect(response[:successful]).not_to be_empty
#     expect(response[:failed]).to be_empty
#   end
# end

# RSpec.describe Renderer::Lambda, integration: true do
#   subject { described_class.handle(event: event, context: {}) }

#   let(:event_source_queue_url) { stack_resources.find { |resource| resource.logical_resource_id == 'RenderingSQSQueue' }.physical_resource_id }
#   let(:pdf_generation_queue_url) { stack_resources.find { |resource| resource.logical_resource_id == 'PDFGenerationSQSQueue' }.physical_resource_id }

#   before(:all) do
#     allow(ENV).to receive(:[]).with('S3_BUCKET') { s3_bucket_name }
#     allow(ENV).to receive(:[]).with('EVENT_SOURCE_QUEUE_URL') { event_source_queue_url }
#     allow(ENV).to receive(:[]).with('PDF_GENERATION_QUEUE_URL') { pdf_generation_queue_url }
#   end

#   include_examples 'RendererLambdaFunction', subject
# end

# RSpec.describe 'RenderingLambdaFunction', acceptance: true do
#   let(:client) { Aws::Lambda::Client.new }
#   let(:renderer_lambda_function) {  stack_resources.find { |resource| resource.logical_resource_id == 'RendererLambdaFunction' }.physical_resource_id }

#   subject do
#     JSON.parse(
#       client.invoke(
#         function_name: renderer_lambda_function,
#         invocation_type: 'RequestResponse',
#         log_type: 'None',
#         payload: JSON.generate(event)
#       ).payload.string,
#       symbolize_names: true
#     end
#   end

#   include_examples 'RendererLambdaFunction', subject[:body]
# end
