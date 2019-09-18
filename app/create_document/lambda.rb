require 'event_stack'
require 'event_handler'
require 'aws-sdk-s3'
require 'down'
require 'document_repository'
require 'pipeline'

module CreateDocument
  class Handler < EventHandler
    def handle(s3_client: Aws::S3::Client.new, document_repository: DocumentRepository)
      input_file = Down.download(params['file_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))

      s3_object_key = "#{params['requestId']}/original/#{input_file.original_filename}"

      File.open(input_file, 'rb') do |file|
        s3_client.put_object(bucket: ENV['S3_BUCKET'], key: s3_object_key, body: file)
      end

      pipeline = Pipeline.build_from_request(params)

      item = {
        id:           params['requestId'],
        input_file:   s3_object_key,
        merge_fields: params['merge_fields'],
        pipeline:     pipeline,
        status:       'pending'
      }

      document_repository.create(item)

      [202, item.slice(:id, :status)]
    rescue Down::Error => e
      [422, id: context['requestId'], status: 'error', message: e.message]
    ensure
      input_file.close unless input_file.nil? || input_file.closed?
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler)

  module_function def handler(**args)
    EVENT_STACK.call(**args)
  end
end
