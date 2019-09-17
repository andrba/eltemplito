require 'event_handler'
require 'aws-sdk-lambda'
require 'document_repository'

module Dispatchr
  module Lambda
    class Handler < EventHandler
      SCHEMA = File.read(File.join(__dir__, 'schema.json'))

      def handle(lambda_client: Aws::Lambda::Client.new, document_repository: DocumentRepository)
        if request['pipeline'].empty?
          document_repository.update(request['id'], status: 'success', document: request['input_file'])
        else
          request.merge('pipeline' => request['pipeline'].drop(1)).tap do |request|
            lambda_client.invoke_async(function_name: ENV[request['pipeline'].first],
                                       invoke_args: JSON.generate(request))
          end
        end
      end
    end

    module_function def handler(event:, context:)
      Handler.stack.call('event' => event, 'context' => context)
    end
  end
end
