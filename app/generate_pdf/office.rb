require 'brotli'
require 'rubygems/package'
require 'fileutils'
require 'stringio'

module GeneratePdf
  module Office
    DEFLATED_SOFFICE_PATH = '/opt/lo.tar.br';
    INFLATED_SOFFICE_PATH = '/tmp/instdir/program/soffice';

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

    def inflate_soffice
      return if File.exists?(INFLATED_SOFFICE_PATH)

      lo_tar = Brotli.inflate(File.binread(DEFLATED_SOFFICE_PATH))
      untar(StringIO.new(lo_tar), '/tmp')
    end

    def perform(file_path:)
      inflate_soffice

      args = DEFAULT_SOFFICE_ARGS + %w[--convert-to pdf --outdir /tmp] + [file_path]

      stdout, stderr, status = Open3.capture3(INFLATED_SOFFICE_PATH, *args, chdir: '/tmp')

      return "/tmp/#{File.basename(file_path, '.*')}.pdf" if status == 0

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

    def untar(io, destination)
      Gem::Package::TarReader.new(io) do |tar|
        tar.each do |tarfile|
          destination_file = File.join(destination, tarfile.full_name)

          if tarfile.directory?
            FileUtils.mkdir_p(destination_file)
          else
            destination_directory = File.dirname(destination_file)
            FileUtils.mkdir_p(destination_directory) unless File.directory?(destination_directory)

            File.open(destination_file, "wb") do |f|
              f.print(tarfile.read)

            end

            FileUtils.chmod_R(0755, destination_file)
          end
        end
      end
    end
  end
end
