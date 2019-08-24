require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-sqs'

s3_bucket = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])
sqs       = Aws::SQS::Client.new(region: ENV['AWS_REGION'])

module Lambda
  module_function

  def handler(event:, context:)
    record = event['Records'].first

    template_file = Down.download(record['template_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))
    rendered_document = Sablon.template(template_file.path).render_to_string(record['merge_fields'])

    file_name = "#{SecureRandom.hex(16)}-#{File.basename(template_file.original_filename)}"

    s3_object = s3_bucket.object(file_name)
    s3_object.put(body: rendered_document)

    sqs.send_message(
      queue_url: ENV['PDF_GENERATION_QUEUE'],
      message_body: JSON.generate(
        s3_object_key: s3_object.key
      )
    )
  ensure
    template_file.close unless template_file.closed?
    File.unlink(template_file.path)
  end
end
