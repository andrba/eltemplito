module PdfGenerator
  DEFAULT_SOFFICE_ARGS = %w[
    --headless
    --invisible
    --nodefault
    --view
    --nolockcheck
    --nologo
    --norestore
    --nofirststartwizard
  ]

  class PdfGenerationError < StandardError; end

  module_function

  def perform(input_filename:, soffice_path:)
    args = DEFAULT_SOFFICE_ARGS + %w[--convert-to pdf --outdir /tmp] + [input_filename]

    stdout, stderr, status = Open3.capture3(soffice_path, args, chdir: '/tmp')

    return stdout if status == 0

    raise PdfGenerationError, stderr
  ensure
    cleanup_tmp_files
  end

  def cleanup_tmp_files
    Dir.foreach('/tmp') do |file|
      if file.end_with?('.tmp') || file.start_with?('OSL_PIPE')
        FileUtils.rm_f(file)
      end
    end
  end
end
