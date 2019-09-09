require 'json'
require 'aws-sdk-lambda'
require 'document_repository'

module Dispatchr
  module Lambda
    Lambda = Aws::Lambda::Client.new

    module_function def handler(event:, context:)
      message = JSON.parse(event['Records'].first['Sns']['Message'])
      if message['pipeline'].empty?
        DocumentRepository.update(message['id'], status: 'success', document: message['input_file'])
      else
        invoke_args = message.merge('pipeline' => message['pipeline'].drop(1))

        Lambda.invoke_async(
          function_name: ENV[message['pipeline'].first],
          invoke_args: JSON.generate(invoke_args)
        )
      end
    end
  end
end
