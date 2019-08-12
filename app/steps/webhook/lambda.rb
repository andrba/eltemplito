require 'httparty'

module Lambda
  module_function

  def handler(event:, :context:)
    url = Aws::S3::Presigner.new.presigned_url(:get_object, bucket: ENV['S3_BUCKET'], key: event[:pdf_file_name])

    HTTParty.post(event[:callback],
                  body: { download_url: url },
                  headers: { 'Content-Type' => 'application/json' })
  end
end
