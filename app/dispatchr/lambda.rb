require 'event_stack'
require 'event_handler'
require 'aws-sdk-lambda'
require 'document_repository'

module Dispatchr
  class Handler < EventHandler
    def handle(lambda_client: Aws::Lambda::Client.new, document_repository: DocumentRepository)
      if params['pipeline'].empty?
        document_repository.update(params['id'], status: 'success', document: params['input_file'])
      else
        invoke_args = params.merge('pipeline' => params['pipeline'].drop(1))
        lambda_client.invoke_async(function_name: ENV[params['pipeline'].first],
                                   invoke_args: JSON.generate(invoke_args)
      end
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler, schema: File.join(__dir__, 'schema.json'))

  module_function def handler(**args)
    EVENT_STACK.call(**args)
  end
end
