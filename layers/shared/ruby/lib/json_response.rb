require 'json'

module JsonResponse
  def json_response(code, body = {})
    {
      'statusCode' => code,
      'headers' => {
        'Content-Type' => 'application/json'
      },
      'body' => JSON.generate(body)
    }
  end
end
