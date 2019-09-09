require 'aws-sdk-s3'
require 'aws-sdk-sns'
require 'office'

module GeneratePdf
  module Lambda
    S3  = Aws::S3::Client.new
    SNS = Aws::SNS::Resource.new

    module_function def handler(event:, context:)
      Office.inflate_soffice

      input_file_name = File.basename(event['input_file'])
      input_file_path = "/tmp/#{event['id']}-#{input_file_name}"

      S3.get_object(bucket: ENV['S3_BUCKET'],
                    key: event['input_file'],
                    response_target: input_file_path)

      output_file_path = Office.perform(file_path: input_file_path)

      s3_object_key = "#{event['id']}/generate-pdf/#{File.basename(input_file_name, '.*')}.pdf"

      File.open(output_file_path, 'rb') do |file|
        S3.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: file)
      end

      SNS.topic(ENV['STATE_CHANGED_TOPIC']).publish(
        message: JSON.generate(event.merge('input_file' => s3_object_key))
      )
    ensure
      [input_file_path, output_file_path].compact.each do |file_path|
        File.delete(file_path) if File.exist?(file_path)
      end
    end
  end
end
