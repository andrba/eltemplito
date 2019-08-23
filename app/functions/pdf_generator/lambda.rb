require 'brotli'
require 'pdf_generator'
require 'aws-sdk-s3'

DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

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
    event.merge!(pdf_file_name: pdf_file_name)
  ensure
    pdf_file_path.close
    pdf_file_path.unlink
  end

  def bucket
    Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])
  end
end
