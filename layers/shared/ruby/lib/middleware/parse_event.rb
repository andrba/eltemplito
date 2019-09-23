require 'json'
require_relative 'parse_event/api_gateway_event_parser'
require_relative 'parse_event/dynamodb_event_parser'
require_relative 'parse_event/sns_event_parser'
require_relative 'parse_event/unknown_event_parser'

class ParseEvent
  EVENT_PARSERS = [
    ApiGatewayEventParser,
    DynamodbEventParser,
    SnsEventParser,
    UnknownEventParser
  ]

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env.merge(parse(env)))
  end

  private

  def parse(env)
    # UnknownEventParser is the last parser in the chain that is always parsable
    EVENT_PARSERS.lazy.map { |parser| parser.new(env) }.find(&:parsable?).parse
  end
end
