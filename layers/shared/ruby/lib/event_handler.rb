require 'middleware/parse_event'
require 'middleware/validate_schema'
require 'middleware/json_response'

class EventHandler
  attr_reader :env

  def self.stack
    Middleware::Builder.new do |b|
      b.use ParseEvent
      b.use ValidateSchema, self::SCHEMA
      b.use JsonResponse
      b.use ->(env) { self.new(env).handle }
    end
  end

  def initialize(env)
    @env = env
  end

  def handle
    raise NotImplemented
  end

  private

  def request
    env['app.request']
  end

  def event_source
    env.dig('event', 'eventSource')
  end
end
