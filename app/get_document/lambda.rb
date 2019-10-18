require 'event_stack'
require 'event_handler'
require 'aws-sdk-s3'
require 'document_repository'

module GetDocument
  class Handler < EventHandler
    def handle(s3_signer: Aws::S3::Presigner.new, document_repository: DocumentRepository)
      if item = document_repository.get(id: params['id'])
        response = item.slice(:id, :status)

        if item[:status] == 'success'
          response[:document_url] = s3_signer.presigned_url(:get_object,
                                                            bucket: ENV['S3_BUCKET'],
                                                            key: item[:document])
        end

        [200, response]
      else
        [404, id: params['id'], status: 'failure', message: 'Document not found']
      end
    end
  end

  EVENT_STACK = EventStack.build(handler: Handler)

  module_function def handler(**args)
    EVENT_STACK.call(args.with_indifferent_access)
  end
end
