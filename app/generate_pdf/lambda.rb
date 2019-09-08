require 'aws-sdk-s3'
require 'aws-sdk-lambda'
require 'aws-ssm-env'
require 'brotli'
require 'office'

module GeneratePdf
  module Lambda
    S3 = Aws::S3::Client.new

    DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
    INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

    AwsSsmEnv.load!(begins_with: "#{ENV['SSM_PATH']}/functions/")

    def inflate_soffice
      return if File.exists?(INFLATED_SOFFICE_PATH)

      File.open(INFLATED_SOFFICE_PATH, "wb") do |f|
        f.write(Brotli.inflate(DEFLATED_SOFFICE_PATH))
      end
    end

    module_function def handler(event:, context:)
      inflate_soffice

      inptu_file_name = File.basename(event['input_file'])
      input_file_path = "/tmp/#{inptu_file_name}"

      S3.get_object(bucket: ENV['S3_BUCKET'],
                    key: event['input_file'],
                    target: input_file_path)

      output_file_path =
        Office.perform(file_path: input_file_path, soffice_path: INFLATED_SOFFICE_PATH)

      File.open(output_file_path, 'rb') do |file|
        S3.put_object(bucket: ENV['S3_BUCKET'],
                      key: "#{event['id']}/generate-pdf/#{File.basename(inptu_file_name)}.pdf",
                      body: file)
      end
    ensure
      [input_file_path, output_file_path].each do |file_path|
        File.delete(file_path) if File.exist?(file_path)
      end
    end
  end
end
