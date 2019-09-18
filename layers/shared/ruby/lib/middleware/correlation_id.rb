require 'json'

class CorrelationId
  def initialize(app)
    @app = app
  end

  def call(env)
    env['x-correlation-id'] =
      if env.dig('event', 'eventSource') == 'aws:apigateway'
        env.dig('context', 'requestId')
      end

    @app.call(env)
  end
end
