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
  system!("rm -rf .layers")

  layer_names =
    Dir['app/functions/*'].map { |dir| dir.split('/').last } & Bundler.load.current_dependencies.flat_map(&:groups).uniq.map(&:to_s)

  bundle_commands =
    layer_names.map do |layer_name|
      FileUtils.mkdir_p(".layers/#{layer_name}/ruby/gems")

      <<-BUNDLE.chomp
        bundle install \
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

  layer_names.each do |layer_name|
    system!("cd .layers/#{layer_name} && \
             mv ruby/2.5.0 ruby/gems/ && \
             rm -rf ruby/gems/2.5.0/cache && \
             rm -rf ruby/2.5.0 && \
             mkdir ruby/lib && \
             cp -r ../../lib/* ruby/lib")
  end

  system!("rm -rf .bundle")
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
