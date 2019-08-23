require 'down'
require 'sablon'
require 'aws-sdk-s3'
require 'aws-sdk-sns'

sns_topic = Aws::SNS::Resource.new(region: ENV['AWS_REGION']).topic(ENV['DOCUMENTS_SNS_TOPIC'])
s3_bucket = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])

module Lambda
  module_function

  def handler(event:, context:)
    template_file = Down.download(event['template_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))
    rendered_document = Sablon.template(template_file.path).render_to_string(event['merge_fields'])

    file_name = "#{SecureRandom.hex(16)}-#{File.basename(template_file.original_filename)}"

    s3_object = s3_bucket.object(file_name)
    s3_object.put(body: rendered_document)

    sns_topic.publish(
      message: JSON.generate(
        event.slice('resource_type', 'resource_id').merge('document_url' => s3_object.presigned_url(:put))
      ),
      message_structure: :json,
      message_attributes: {
        type: {
          data_type: :string,
          string_value: event['type'] || 'unknown'
        },
        file_format: {
          data_type: :string,
          string_value: File.extname(file_name)
        }
      }
    )
  ensure
    template_file.close unless template_file.closed?
    File.unlink(template_file.path)
  end
end
