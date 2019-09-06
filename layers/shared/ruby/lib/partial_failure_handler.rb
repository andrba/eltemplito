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
        block.call(record['eventName'], parse_dynamodb_image(record['dynamodb']['newImage']))
      rescue => exception
        failures[record['eventId']] = [exception.message, exception.backtrace]
      end
    end

    if failures.any?
      # TODO: Notify via SNS
      puts failures
    end
  end

  def parse_dynamodb_image(record)
    record.each_with_object({}) do |(key, value), memo|
      memo[k] = value.first.last
    end
  end
end
