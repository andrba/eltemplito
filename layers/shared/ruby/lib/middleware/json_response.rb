require 'json'

class JsonResponse
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)

    if env.dig('event', 'eventSource') == 'aws:apigateway'
      {
        'statusCode' => response[:status_code],
        'headers' => {
          'Content-Type' => 'application/json'
        },
        'body' => JSON.generate(response[:body])
      }
    else
      response
    end
  end
end
