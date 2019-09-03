require 'dynamoid'
require 'file_uploader'

class Document
  include Dynamoid::Document
  extend CarrierWave::Mount

  table name: ENV['DOCUMENTS_TABLE'], key: :id

  field :file, :string
  field :status, :string
  field :pipeline, :array

  mount_uploader :file, FileUploader

  def save
    self.store_file!
    super
  end

  # private

  # attr_accessor :upload_file

  # def upload_file
  #   return if upload_file.nil?

  #   s3_object = S3.bucket(ENV['S3_BUCKET']).
  #                  object("#{id}/#{File.basename(upload_file.original_filename)}").
  #                  upload_file(upload_file.path)


  # def validate_file_format
  #   File.basename(upload_file_path.original_filename)
  # end
end
