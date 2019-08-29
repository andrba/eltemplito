require 'bundler'
require 'rake'
require 'fileutils'
require 'etc'

def system!(*args)
  system(*args) || abort("\n== Command #{args} failed ==")
end

task :build do
  system!("sam build")
end

task :build_layers do
  begin
    system!("rm -rf .layers")

    gem_layer_names = Bundler.load.current_dependencies.flat_map(&:groups).uniq.map(&:to_s) - ['test']

    bundle_commands =
      gem_layer_names.map do |layer_name|
        FileUtils.mkdir_p(".layers/#{layer_name}/ruby/gems")

        <<-BUNDLE.chomp
          BUNDLE_IGNORE_CONFIG=1 bundle install \
            --jobs=#{Etc.nprocessors} \
            --path=/var/layer/.layers/#{layer_name} \
            --without test \
            --with=default #{layer_name}
        BUNDLE
      end

    system!("docker run --rm \
            -v $PWD:/var/layer \
            -w /var/layer \
            lambci/lambda:build-ruby2.5 \
            /bin/bash -c \"#{bundle_commands.join(' && ')}\"")

    gem_layer_names.each do |layer_name|
      system!("cd .layers/#{layer_name} && \
              mv ruby/2.5.0 ruby/gems/ && \
              rm -rf ruby/gems/2.5.0/cache && \
              rm -rf ruby/2.5.0")
    end

    FileUtils.mkdir_p(".layers/lib/ruby")
    FileUtils.ln_s(File.expand_path("lib/"), File.expand_path(".layers/lib/ruby/lib"), force: true)
  ensure
    system!("rm -rf .bundle")
  end
end

task :package, [:bucket] do |_, args|
  system!("sam package \
    --s3-bucket=#{args.bucket} \
    --template-file=.aws-sam/build/template.yaml \
    --output-template-file=.aws-sam/build/packaged-template.yaml")
end

task :deploy, [:product, :environment] do |_, args|
  system!("sam deploy \
    --template-file .aws-sam/build/packaged-template.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides Product=#{args.product} Environment=#{args.environment} \
    --stack-name #{args.product}")
end
