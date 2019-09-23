require 'middleware'
require 'middleware/parse_event'
require 'middleware/validate_schema'
require 'middleware/json_response'
require 'middleware/partial_failure_handler'

module EventStack
  module_function def build(handler:, schema: nil)
    Middleware::Builder.new do |b|
      b.use ParseEvent
      b.use PartialFailureHandler
      b.use ValidateSchema, schema
      b.use JsonResponse
      b.use ->(env) { handler.new(env).handle }
    end
  end
end
