require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-sqs'
require 'partial_failurure_handler'

S3_BUCKET = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])
RENDERING_QUEUE = Aws::SQS::Client.new(region: ENV['AWS_REGION']).queues[ENV['RENDERING_QUEUE']]
PDF_GENERATION_QUEUE = Aws::SQS::Client.new(region: ENV['AWS_REGION']).queues[ENV['PDF_GENERATION_QUEUE']]

module Lambda
  module_function

  def handler(event:, context:)
    PartialFailureHandler.new(queue: RENDERING_QUEUE, event: event).map do |record|
      begin
        template_file = Down.download(record['template_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))
        rendered_document = Sablon.template(template_file.path).render_to_string(record['merge_fields'])

        file_name = "#{SecureRandom.hex(16)}-#{File.basename(template_file.original_filename)}"

        S3_BUCKET.object(file_name).put(body: rendered_document)

        {
          id: file_name,
          message_body: JSON.generate(
            s3_object_key: file_name
          )
        }
      ensure
        template_file.close unless template_file.closed?
        File.unlink(template_file.path)
      end
    end

    PDF_GENERATION_QUEUE.send_messages(entries: _)
  end
end
