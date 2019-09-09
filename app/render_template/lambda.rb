require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-sns'

module RenderTemplate
  module Lambda
    S3  = Aws::S3::Client.new
    SNS = Aws::SNS::Resource.new

    module_function def handler(event:, context:)
      file_name = File.basename(event['input_file'])
      file_path = "/tmp/#{file_name}"

      S3.get_object(bucket: ENV['S3_BUCKET'],
                    key: event['input_file'],
                    response_target: file_path)

      rendered_document = Sablon.template(file_path).render_to_string(event['merge_fields'])

      s3_object_key = "#{event['id']}/render-template/#{file_name}"

      S3.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: rendered_document)

      SNS.topic(ENV['STATE_CHANGED_TOPIC']).publish(
        message: JSON.generate(event.merge('input_file' => s3_object_key))
      )
    ensure
      File.delete(file_path) if File.exist?(file_path)
    end
  end
end
