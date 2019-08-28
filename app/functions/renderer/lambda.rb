require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-sqs'
require 'partial_failure_handler'

S3_BUCKET = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])
PDF_GENERATION_QUEUE = Aws::SQS::Resource.new(region: ENV['AWS_REGION']).queue(ENV['PDF_GENERATION_QUEUE_URL'])

module Lambda
  module_function

  def handler(event:, context:)
    pdf_generation_messages =
      PartialFailureHandler.new(event).map do |params|
        begin
          template_file = Down.download(params['template_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))
          rendered_document = Sablon.template(template_file.path).render_to_string(params['merge_fields'])

          document_id = SecureRandom.uuid
          s3_document_name = "#{document_id}-#{File.basename(template_file.original_filename)}"

          S3_BUCKET.object(s3_document_name).put(body: rendered_document)

          {
            id: document_id,
            message_body: JSON.generate(
              s3_document_name: s3_document_name
            )
          }
        ensure
          template_file.close! unless template_file.nil? || template_file.closed?
        end
      end

    PDF_GENERATION_QUEUE.send_messages(entries: pdf_generation_messages)
  end
end
