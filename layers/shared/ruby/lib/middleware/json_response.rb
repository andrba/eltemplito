require 'json'

class JsonResponse
  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)

    return response unless env[:source] == 'apigateway'

    code, body = *response

    {
      'statusCode' => code,
      'headers' => {
        'Content-Type' => 'application/json'
      },
      'body' => JSON.generate(body)
    }
  end
end
