class PartialFailureHandler
  include Enumerable

  attr_reader \
    :params,
    :failures

  def initialize(params)
    @failures = {}
    @params = params
  end

  def each(&block)
    return to_enum(:each) unless block_given?

    params.each do |record|
      begin
        block.call(record['eventName'], record['dynamodb']['NewImage'])
      rescue => exception
        failures[record['eventId']] = [exception.message, exception.backtrace]
      end
    end

    if failures.any?
      # TODO: Notify via SNS
      puts failures
    end
  end
end
