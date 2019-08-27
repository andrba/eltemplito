require 'json'
require 'aws-sdk-sqs'

class PartialFailureHandler
  include Enumerable

  attr_reader \
    :event,
    :failures,
    :queue

  class PartialFailure < StandardError; end

  def initialize(event)
    @failures = {}
    @event = event
    @queue = Aws::SQS::Resource.new(region: ENV['AWS_REGION']).queue(ENV['EVENT_SOURCE_QUEUE_URL'])
  end

  def each(&block)
    return to_enum(:each) unless block_given?

    event['Records'].each do |record|
      begin
        block.call(JSON.parse(record))
      rescue => exception
        failures[record['messageId']] = [exception.message, exception.backtrace]
      end
    end

    if failures.any?
      delete_succeeded_messages
      raise PartialFailure, "Failed SQS messages in #{queue.attributes['QueueArn']}: #{failures}"
    end
  end

  def delete_succeeded_messages
    return if succeeded_records.none?

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
    event['Records'].reject { |record| failures[record['messageId']] }
  end
end
