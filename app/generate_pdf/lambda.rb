require 'event_handler'
require 'aws-sdk-s3'
require 'aws-sdk-sns'
require 'office'

module GeneratePdf
  module Lambda
    class Handler < EventHandler
      SCHEMA = File.read(File.join(__dir__, 'schema.json'))

      def handle(s3_client: Aws::S3::Client.new, sns_client: Aws::SNS::Client.new)
        input_file_path = "/tmp/#{File.basename(request['input_file'])}"

        s3_client.get_object(bucket: ENV['S3_BUCKET'],
                             key: request['input_file'],
                             response_target: input_file_path)

        output_file_path = Office.perform(file_path: input_file_path)

        s3_object_key = "#{request['id']}/generate-pdf/#{File.basename(request['input_file'], '.*')}.pdf"

        File.open(output_file_path, 'rb') do |file|
          s3_client.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: file)
        end

        event.merge('input_file' => s3_object_key).tap do |response|
          sns_client.publish_topic(topic_name: ENV['STATE_CHANGED_TOPIC'],
                                   message: JSON.generate(response))
        end
      ensure
        [input_file_path, output_file_path].compact.each do |file_path|
          File.delete(file_path) if File.exist?(file_path)
        end
      end

    module_function def handler(event:, context:)
      Handler.stack.call('event' => event, 'context' => context)
    end
  end
end
