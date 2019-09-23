require 'event_stack'
require 'event_handler'
require 'aws-sdk-sns'
require 'aws-sdk-s3'

module ListenDocumentStream
  class Handler < EventHandler
    def handle(sns_client: Aws::SNS::Client.new, s3_signer: Aws::S3::Presigner.new)
      return unless %w[INSERT MODIFY].include?(params[:_eventName])

      response = params.slice(:id, :status)

      if params[:status] == 'pending'
        response.merge!(params.slice(:input_file, :merge_fields, :pipeline))
        sns_client.publish(topic_arn: ENV['STATE_CHANGED_TOPIC'],
                           message: JSON.generate(response))
      else
        if params[:status] == 'success'
          response[:document_url] = s3_signer.presigned_url(:get_object,
                                                            bucket: ENV['S3_BUCKET'],
                                                            key: params[:document])
        end

        sns_client.publish(topic_arn: ENV['DOCUMENT_CREATED_TOPIC'],
                           message: JSON.generate(response))
      end
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler, schema: File.join(__dir__, 'schema.json'))

  module_function def handler(**args)
    EVENT_STACK.call(args.with_indifferent_access)
  end
end
