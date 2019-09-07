require 'down'
require 'sablon'
require 'json'
require 'aws-sdk-s3'
require 'aws-sdk-lambda'

module RenderTemplate
  module Lambda
    S3      = Aws::S3::Client.new
    Lambda  = Aws::Lambda::Resource.new

    module_function def handler(event:, context:)
      file_name = File.basename(event['input_file'])
      file_path = "/tmp/#{file_name}"

      S3.get_object(bucket: ENV['S3_BUCKET'],
                    key: event['input_file'],
                    target: file_path)

      rendered_document = Sablon.template(file_path).render_to_string(event['merge_fields'])

      s3_object = S3.put_object(bucket: [ENV['S3_BUCKET'],
                                key: "#{event['id']}/rendered/#{file_name}",
                                body: rendered_document)

      Lambda.invoke_async(
        function_name: ENV['DISPATCHR_FUNCTION'],
        invoke_args: JSON.generate(event.merge('input_file' s3_object.key))
      )
    ensure
      File.delete(file_path) if File.exist?(file_path)
    end
  end
end
