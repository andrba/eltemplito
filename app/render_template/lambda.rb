require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-lambda'

module RenderTemplate
  module Lambda
    S3 = Aws::S3::Resource.new
    SNS = Aws::SNS::Resource.new
    SQS = Aws::SQS::Resource.new

    module_function def handler(event:, context:)
      input_file = Tempfile.new('input_file')
      input_file.write S3.bucket(ENV['S3_BUCKET'].object(event['input_file']).get.body
      input_file.close

      rendered_document = Sablon.template(input_file.path).render_to_string(params['merge_fields'])

      document_id = SecureRandom.uuid
      s3_document_name = "#{document_id}-#{File.basename(input_file.original_filename)}"

      S3.bucket([ENV['S3_BUCKET']).object(s3_document_name).put(body: rendered_document)

      params.slice('output_format').merge!('document_url' => s3_object.presigned_url(:get))
    ensure
      input_file.close unless input_file.nil? || input_file.closed?
    end
  end
end
