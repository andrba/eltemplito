require 'event_stack'
require 'event_handler'
require 'sablon'
require 'aws-sdk-s3'
require 'aws-sdk-sns'

module RenderTemplate
  class Handler < EventHandler
    def handle(s3_client: Aws::S3::Client.new, sns_client: Aws::SNS::Client.new)
      input_file_path = "/tmp/#{File.basename(params['input_file'])}"
      s3_client.get_object(bucket: ENV['S3_BUCKET'],
                           key: params['input_file'],
                           response_target: input_file_path)

      rendered_document = Sablon.template(input_file_path).render_to_string(params['merge_fields'])

      s3_object_key = "#{params['id']}/render-template/#{File.basename(params['input_file'])}"
      s3_client.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: rendered_document)

      sns_client.publish(topic_arn: ENV['STATE_CHANGED_TOPIC'],
                         message: JSON.generate(params.merge('input_file' => s3_object_key)))
    ensure
      File.delete(input_file_path) if File.exist?(input_file_path)
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler, schema: File.join(__dir__, 'schema.json'))

  module_function def handler(**args)
    EVENT_STACK.call(**args)
  end
end
