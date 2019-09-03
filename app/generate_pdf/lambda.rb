require 'brotli'
require 'down'
require 'pdf_generator'
require 'aws-sdk-s3'
require 'aws-sdk-sns'
require 'partial_failurure_handler'

module PDFGenerator::Lambda
  S3 = Aws::S3::Resource.new
  SNS = Aws::SNS::Resource.new

  DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
  INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

  def inflate_soffice
    return if File.exists?(INFLATED_SOFFICE_PATH)

    File.open(INFLATED_SOFFICE_PATH, "wb") do |f|
      f.write(Brotli.inflate(DEFLATED_SOFFICE_PATH))
    end
  end

  module_function def handler(event:, context:)
    inflate_soffice

    PartialFailureHandler.new(event).map do |params|
      begin
        document_file = Down.download(params['document_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))

        pdf_file_path = PdfGenerator.perform(file_path: template_file.path, soffice_path: INFLATED_SOFFICE_PATH)
        pdf_file_name = File.basename(pdf_file_path, ".*")

        s3_object = S3.bucket(ENV['S3_BUCKET']).object(pdf_file_name).upload_file(pdf_file_path)

        SNS.topic(ENV['EVENT_DEST_SNS_TOPIC']).publish(
          message: JSON.generate('document_url' => s3_object.presigned_url(:put)),
          message_attributes: params['message_attribures'] || {}
        )
      ensure
        [document_file, pdf_file_path].each do |file_path|
          file_path.close! unless file_path.nil? || file_path.closed?
        end
      end
    end
  end
end
