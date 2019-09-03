require 'carrierwave-aws'

class FileUploader < Carrierwave::Uploader::Base
  storage :aws

  # # You can find a full list of custom headers in AWS SDK documentation on
  # # AWS::S3::S3Object
  # def download_url(filename)
  #   url(response_content_disposition: %Q{attachment; filename="#{filename}"})
  # end
end
