require 'aws-sdk-s3'
require 'down'
require 'document_repository'
require 'json_response'
require 'pipeline'

module CreateDocument
  module Lambda
    extend JsonResponse

    S3 = Aws::S3::Resource.new
    DB = Aws::DynamoDB::Resource.new

    module_function def handler(event:, context:)
      request = JSON.parse(event['body'].to_s)

      input_file = Down.download(request['file_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))

      s3_object_key = "#{request['request_id']}/original/#{input_file.original_filename}"

      s3_object = S3.bucket(ENV['S3_BUCKET']).
                    object(s3_object_key).
                    upload_file(input_file.path)

      pipeline = Pipeline.build_from_request(request)

      item = {
        id:           request['request_id'],
        input_file:   s3_object_key,
        merge_fields: request['merge_fields'],
        pipeline:     pipeline,
        status:       'pending'
      }

      DocumentRepository.create(item)

      json_response(202, item.slice(:id, :status))
    rescue Down::ClientError => e
      json_response(422, id: request['request_id'], status: 'error', message: e.message)
    end
  end
end
