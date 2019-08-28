require 'brotli'
require 'pdf_generator'
require 'aws-sdk-s3'
require 'aws-sdk-sns'
require 'partial_failurure_handler'

DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

S3_BUCKET = Aws::S3::Resource.new(region: ENV['AWS_REGION']).bucket(ENV['S3_BUCKET'])
DOCUMENTS_SNS_TOPIC = Aws::SNS::Resource.new(region: ENV['AWS_REGION']).topic(ENV['DOCUMENTS_SNS_TOPIC'])

File.open(INFLATED_SOFFICE_PATH, "wb") do |f|
  f.write(Brotli.inflate(DEFLATED_SOFFICE_PATH))
end

module Lambda
  module_function

  def handler(event:, context:)
    PartialFailureHandler.new(event).map do |params|
      begin
        document_file_path = "tmp/#{params['document_s3_path']}"
        S3_BUCKET.object(event['s3_document_name']).download_file(document_file_path)

        pdf_file_path = PdfGenerator.perform(file_path: document_file_path, soffice_path: INFLATED_SOFFICE_PATH)
        pdf_file_name = File.basename(pdf_file_path, ".*")

        s3_object = S3_BUCKET.object(pdf_file_name).upload_file(pdf_file_path)

        sns_topic.publish(
          message: JSON.generate('document_url' => s3_object.presigned_url(:put)),
          message_structure: :json
        )
      ensure
        [document_file_path, pdf_file_path].each do |file_path|
          file_path.close! unless file_path.nil? || file_path.closed?
        end
      end
    end
  end
end
