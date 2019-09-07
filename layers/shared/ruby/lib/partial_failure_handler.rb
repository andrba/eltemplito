class PartialFailureHandler
  include Enumerable

  attr_reader \
    :event,
    :failures

  def initialize(event)
    @failures = {}
    @event = event
  end

  def each(&block)
    return to_enum(:each) unless block_given?

    event['Records'].each do |record|
      begin
        block.call(record['eventName'], dynamodb_image_to_hash(record['dynamodb']['NewImage']))
      rescue => exception
        failures[record['eventId']] = [exception.message, exception.backtrace]
      end
    end

    if failures.any?
      # TODO: Notify via SNS
      puts failures
    end
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

    # puts record
    # record.each_with_object({}) do |(key, value), memo|
    #   memo[k] = value.first.last
    # end
  end
end
