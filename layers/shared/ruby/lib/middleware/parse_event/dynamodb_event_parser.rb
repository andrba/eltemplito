class ParseEvent
  class DynamodbEventParser
    SOURCE = 'dynamodb'

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def parsable?
      records && records.first[:eventSourceARN].to_s.start_with?('arn:aws:dynamodb')
    end

    def parse
      {
        params: records.map { |record|
                  dynamodb_image_to_hash(record.dig(:dynamodb, :NewImage)).merge(
                    _eventName: record[:eventName],
                    _eventId:   record[:eventId])
                },
        source: SOURCE
      }
    end

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

    def records
      env.dig(:event, :Records)
    end
  end
end
