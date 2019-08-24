require 'brotli'
require 'pdf_generator'
require 'aws-sdk-s3'
require 'aws-sdk-sns'

DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

s3_bucket = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])
sns_topic = Aws::SNS::Resource.new(region: ENV['AWS_REGION']).topic(ENV['DOCUMENTS_SNS_TOPIC'])

File.open(INFLATED_SOFFICE_PATH, "wb") do |f|
  f.write(Brotli.inflate(DEFLATED_SOFFICE_PATH))
end

module Lambda
  module_function

  def handler(event:, context:)
    rendered_file_path = "tmp/#{event[:rendered_file_name]}"
    bucket.object(event[:rendered_file_name]).get(response_target: rendered_file_path)

    pdf_file_path = PdfGenerator.perform(file_path: rendered_file_path, soffice_path: INFLATED_SOFFICE_PATH)
    pdf_file_name = File.basename(pdf_file_path, ".*")

    bucket.object(pdf_file_name).upload_file(pdf_file_path)
    sns_topic.publish(
      message: JSON.generate(
        event.slice('resource_identifier').merge('document_url' => s3_object.presigned_url(:put))
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
    pdf_file_path.close
    pdf_file_path.unlink
  end

  def bucket
    Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])
  end
end
