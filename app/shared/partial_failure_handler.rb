class PartialFailureHandler
  include Enumerable

  attr_reader \
    :event,
    :queue,
    :succeeded_records,
    :failures

  def initialize(queue:, event:)
    @queue = queue
    @event = event
    @failures = {}
  end

  def each(&block)
    return to_enum(:each) unless block_given?

    event['Records'].each do |record|
      begin
        block.call(record)
      rescue => exception
        failures[record['messageId']] = exception.message
      end
    end

    if failures.any?
      delete_succeeded_messages
      raise PartialFailure, "Failed SQS messages in #{queue}: #{partial_failure_message}"
    end
  end

  def delete_succeeded_messages
    queue.delete_messages(
      entries: succeeded_records.map do |record|
        {
          id: record['messageId'],
          receipt_handle: record['receiptHandle']
        }
      end
    )
  end

  def succeeded_records
    event['Records'].reject { |record| failures[record['messageId'] }
  end
end
