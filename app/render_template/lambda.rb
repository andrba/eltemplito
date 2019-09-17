require 'event_handler'
require 'sablon'
require 'aws-sdk-s3'
require 'aws-sdk-sns'

module RenderTemplate
  module Lambda
    class Handler < EventHandler
      SCHEMA = File.read(File.join(__dir__, 'schema.json'))

      def handle(s3_client: Aws::S3::Client.new, sns_client: Aws::SNS::Client.new)
        input_file_path = "/tmp/#{File.basename(request['input_file'])}"
        s3_client.get_object(bucket: ENV['S3_BUCKET'],
                             key: request['input_file']),
                             response_target: input_file_path)

        rendered_document = Sablon.template(input_file_path).render_to_string(request['merge_fields'])

        s3_object_key = "#{request['id']}/render-template/#{File.basename(request['input_file'])}"
        s3_client.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: rendered_document)

        request.merge('input_file' => s3_object_key).tap do |response|
          sns_client.publish_topic(topic_name: ENV['STATE_CHANGED_TOPIC'],
                                   message: JSON.generate(response))
        end
      ensure
        File.delete(input_file_path) if File.exist?(input_file_path)
      end
    end

    module_function def handler(event:, context:)
      Handler.stack.call('event' => event, 'context' => context)
    end
  end
end
