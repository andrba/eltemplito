require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-sns'
require 'partial_failure_handler'

module Renderer::Lambda
  S3 = Aws::S3::Resource.new
  SNS = Aws::SNS::Resource.new
  SQS = Aws::SQS::Resource.new

  module_function def handler(event:, context:)
    PartialFailureHandler.new(event).map do |params|
      begin
        template_file = Down.download(params['document_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))
        rendered_document = Sablon.template(template_file.path).render_to_string(params['merge_fields'])

        document_id = SecureRandom.uuid
        s3_document_name = "#{document_id}-#{File.basename(template_file.original_filename)}"

        S3.bucket([ENV['S3_BUCKET']).object(s3_document_name).put(body: rendered_document)

        params.slice('output_format').merge!('document_url' => s3_object.presigned_url(:get))
      ensure
        template_file.close! unless template_file.nil? || template_file.closed?
      end
    end


  end
end
