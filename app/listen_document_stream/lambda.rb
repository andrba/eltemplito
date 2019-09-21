require 'event_stack'
require 'event_handler'
require 'aws-sdk-sns'
require 'aws-sdk-s3'
require 'partial_failure_handler'

module ListenDocumentStream
  class Handler < EventHandler
    def handle(sns_client: Aws::SNS::Client.new, s3_signer: Aws::S3::Presigner.new)
      PartialFailureHandler.new(params).map do |event_name, record|
        next unless %w[INSERT MODIFY].include?(event_name)

        if record['status'] == 'pending'
          sns_client.publish(topic_arn: ENV['STATE_CHANGED_TOPIC'],
                             message: JSON.generate(record))
        else
          response = record.slice('id', 'status')

          if record['status'] == 'success'
            response['document_url'] = s3_signer.presigned_url(:get_object,
                                                               bucket: ENV['S3_BUCKET'],
                                                               key: record['document'])
          end

          sns_client.publish(topic_arn: ENV['DOCUMENT_CREATED_TOPIC'],
                             message: JSON.generate(response))
        end
      end
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler, schema: File.join(__dir__, 'schema.json'))

  module_function def handler(**args)
    EVENT_STACK.call(**args)
  end
end
