require 'aws-sdk-lambda'
require 'aws-ssm-env'
require 'document_repository'

module Dispatchr
  module Lambda
    Lambda = Aws::Lambda::Client.new

    AwsSsmEnv.load!(begins_with: "#{ENV['SSM_PATH']}/functions/")

    module_function def handler(event:, context:)
      if event['pipeline'].empty?
        DocumentRepository.update(event['id'], status: 'success', document: event['input_file'])
      else
        invoke_args = event.merge('pipeline' => event['pipeline'].drop(1))

        Lambda.invoke_async(
          function_name: ENV[event['pipeline'].first],
          invoke_args: JSON.generate(invoke_args)
        )
      end
    end
  end
end
