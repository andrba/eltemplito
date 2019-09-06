require 'aws-sdk-lambda'
require 'aws-sdk-sns'
require 'aws-sdk-s3'
require 'partial_failure_handler'

module ListenDocumentStream::Lambda
  Lambda = Aws::Lambda::Client.new
  S3     = Aws::S3::Resource.new
  SNS    = Aws::SNS::Resource.new

  module_function def handler(event:, context:)
    PartialFailureHandler.new(event).map do |event_name, params|
      case event_name
      when 'INSERT'
        Lambda.invoke_async(
          function_name: ENV['DISPATCHR_FUNCTION'],
          invoke_args: params
        )
      when 'MODIFY'
        response = body.slice('id', 'status')

        if body['status'] == 'success'
          document_url = S3.bucket(ENV['S3_BUCKET']).object(body['document']).presigned_url(:get)
          response['document_url'] = document_url
        end

        SNS.topic(ENV['DOCUMENTS_TOPIC']).publish(
          message: JSON.generate(response),
          message_attributes: {}
        )
      end
    end
  end
end
