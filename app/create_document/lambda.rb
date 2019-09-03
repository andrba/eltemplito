require 'down'
require 'document'
require 'aws-sdk-s3'

module CreateDocument::Lambda
  S3 = Aws::S3::Resource.new

  module_function def handler(event:, context:)
    request = JSON.parse(event['body'])

    document_file = Down.download(request['document_url'], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))

    document = Document.new(id: SecureRandom.uuid, file: document_file, pipeline: [])

    if document.save
      json_response(202, id: document.id)
    else
      json_response(422, document.errors)
    end
  end

  private

  def json_response(code, body = {})
    {
      'statusCode' => code,
      'headers' => {
        'Content-Type' => 'application/json'
      },
      'body' => JSON.generate(body)
    }
  end
end
