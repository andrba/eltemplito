require 'down'
require 'sablon'
require 'aws-sdk-s3'

module Lambda
  module_function

  def handler(event:, context:)
    template_file = Down.download(event[:template_url], max_size: ENV.fetch('MAX_TEMPLATE_SIZE', 5 * 1024 * 1024))

    rendered_file_name = "#{SecureRandom.hex(16)}-#{File.basename(template_file.original_filename, '.*')}"
    rendered_file_path = "/tmp/#{rendered_file_name}"

    Sablon.template(template_file).render_to_file(rendered_file_path, merge_fields)

    Aws::S3::Resource.new.bucket(ENV['S3_BUCKET']).object(rendered_file_name).upload_file(rendered_file_path)
    event.merge!(rendered_file_name: rendered_file_name)
  ensure
    [template_file, rendered_file].map(&:close).map(&:unlink)
  end
end
