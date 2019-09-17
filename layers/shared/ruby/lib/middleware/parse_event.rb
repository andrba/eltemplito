require 'json'

class ParseEvent
  def initialize(app)
    @app = app
  end

  def call(env)
    env['app.request'] =
      case env.dig('event', 'eventSource')
      when 'aws:dynamodb'
        env.dig('event', 'Records')
      when 'aws:sns'
        JSON.parse(env.dig('event', 'Records').first.dig('Sns', 'Message'))
      when 'aws:apigateway'
        JSON.parse(env.dig('event', 'body').to_s)
      else
        env['event']
      end

    @app.call(env)
  end
end
