require 'aws-sdk-lambda'
require 'document_repository'

module Dispatchr::Lambda
  Lambda = Aws::Lambda::Client.new

  module_function def handler(event:, context:)
    if event['pipeline'].empty?
      DocumentRepository.update(event['id'], status: 'success', document: event['input_file'])
    else
      Lambda.invoke_async(
        function_name: ENV[event['pipeline'].first],
        invoke_args: event.merge('pipeline' => event['pipeline'].drop(1))
      )
    end
  end
end
