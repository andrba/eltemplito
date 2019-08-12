require 'rake'

def system!(*args)
  system(*args) || abort("\n== Command #{args} failed ==")
end

task :build do
  system!("sam build")
end

task :package, [:bucket] do |_, args|
  system!("sam package \
    --s3-bucket=#{args.bucket} \
    --template-file=template.yaml \
    --output-template-file=.aws-sam/packaged-template.yaml")
end

task :deploy, [:product, :environment] do |_, args|
  system!("aws cloudformation deploy \
    --template-file .aws-sam/packaged-template.yaml \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides Product=#{args.product} Environment=#{args.environment} \
    --stack-name #{args.product}")
end
