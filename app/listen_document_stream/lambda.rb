require 'aws-sdk-sns'
require 'aws-sdk-s3'
require 'partial_failure_handler'

module ListenDocumentStream
  module Lambda
    S3     = Aws::S3::Resource.new
    SNS    = Aws::SNS::Resource.new

    module_function def handler(event:, context:)
      PartialFailureHandler.new(event).map do |event_name, params|
        case event_name
        when 'INSERT'
          SNS.topic(ENV['STATE_CHANGED_TOPIC']).publish(message: JSON.generate(params))
        when 'MODIFY'
          response = params.slice('id', 'status')

          if params['status'] == 'success'
            document_url = S3.bucket(ENV['S3_BUCKET']).object(params['document']).presigned_url(:get)
            response['document_url'] = document_url
          end

          SNS.topic(ENV['DOCUMENT_CREATED_TOPIC']).publish(message: JSON.generate(response))
        end
      end
    end
  end
end
