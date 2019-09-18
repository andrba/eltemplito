require 'json'

class ParseEvent
  def initialize(app)
    @app = app
  end

  def call(env)
    env['params'] =
      case env.dig('event', 'eventSource')
      when 'aws:dynamodb'
        env.dig('event', 'Records').map { |record| dynamodb_image_to_hash(record) }
      when 'aws:sns'
        JSON.parse(env.dig('event', 'Records').first.dig('Sns', 'Message'))
      when 'aws:apigateway'
        JSON.parse(env.dig('event', 'body').to_s)
      else
        env['event']
      end

    @app.call(env)
  end

  private

  def dynamodb_image_to_hash(record)
    record.each_with_object({}) do |(key, value), memo|
      parsed_value = nil
      value.each do |type, type_value|
        parsed_value =
          case type.to_s
            when 'S' then type_value.to_s
            when 'N' then type_value.to_i
            when 'L' then type_value.map(&:values).flatten
            when 'M' then dynamodb_image_to_hash(type_value)
            else type_value
          end
      end
      memo[key] = parsed_value
    end
  end
end
