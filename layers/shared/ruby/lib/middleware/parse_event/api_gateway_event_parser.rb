class ParseEvent
  class ApiGatewayEventParser
    SOURCE = 'apigateway'

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def parsable?
      env.dig(:event, :requestContext)
    end

    def parse
      {
        params: json_body.merge('x-corellation-id' => env.dig(:event, :requestContext, :requestId)),
        source: SOURCE
      }
    end

    private

    def json_body
      JSON.parse(env.dig(:event, :body).to_s)
    end
  end
end
