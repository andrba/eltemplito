require 'bundler'
require 'rake'
require 'fileutils'
require 'etc'
require 'securerandom'

def system!(*args)
  system(*args) || abort("\n== Command #{args} failed ==")
end

task :build do
  system!("sam build")
end

task :build_layers, [:layer] do |_, args|
  bundle_groups = Bundler.load.current_dependencies.flat_map(&:groups).uniq.map(&:to_s) - ['test', 'development']

  begin
    layers = args.layer && [args.layer] & bundle_groups || bundle_groups

    if layers.none?
      puts "No #{layers} groups found in Gemfile"
      exit(1)
    end

    bundle_commands =
      layers.map do |layer_name|
        Dir["layers/#{layer_name}/ruby/*"].each do |file|
          FileUtils.rm_rf(file) unless file.end_with?('lib')
        end

        <<-BUNDLE.chomp
          BUNDLE_IGNORE_CONFIG=1 bundle install \
            --jobs=#{Etc.nprocessors} \
            --path=/var/layer/layers/#{layer_name} \
            --without test development \
            --with=default #{layer_name}
        BUNDLE
      end

    system!("docker run --rm \
            -v $PWD:/var/layer \
            -w /var/layer \
            lambci/lambda:build-ruby2.5 \
            /bin/bash -c \"#{bundle_commands.join(' && ')}\"")

    layers.each do |layer_name|
      system!("cd layers/#{layer_name} && \
              mkdir -p ruby/gems && \
              mv ruby/2.5.0 ruby/gems/ && \
              rm -rf ruby/gems/2.5.0/cache && \
              rm -rf ruby/2.5.0")
    end
  ensure
    dirs_to_remove = [".bundle"] + Dir['layers/*'] - bundle_groups.map { |name| "layers/#{name}" }
    FileUtils.rm_r dirs_to_remove
  end
end

task :deploy, [:product, :environment, :bucket] do |_, args|
  system!("sam package \
    --s3-bucket=#{args.bucket} \
    --template-file=.aws-sam/build/template.yaml \
    --output-template-file=.aws-sam/build/packaged-template.yaml")

  # https://github.com/awslabs/serverless-application-model/issues/305
  swagger_s3_path = "s3://#{args.bucket}/#{SecureRandom.hex}-swagger.yaml"
  system!("aws s3 cp swagger.yaml #{swagger_s3_path}")

  system!("sam deploy \
    --template-file .aws-sam/build/packaged-template.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides \
      Product=#{args.product} \
      Environment=#{args.environment} \
      SwaggerS3Path=#{swagger_s3_path} \
    --stack-name #{args.product} \
    --no-fail-on-empty-changeset")

  system!("aws cloudformation describe-stacks \
    --stack-name #{args.product} \
    --query \"Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue\" \
    --output text")
end
