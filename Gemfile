source 'https://rubygems.org'

gem 'aws-sdk-s3'
gem 'aws-sdk-sqs'

group :pdf_generator, optional: true do
  gem 'brotli'
  gem 'aws-sdk-sns'
end

group :renderer, :test, optional: true do
  gem 'down'
  gem 'sablon'
end

group :test do
  gem 'rspec'
  gem 'aws-sdk-cloudformation'
end
