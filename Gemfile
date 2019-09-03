source 'https://rubygems.org'

group :generate_pdf, optional: true do
  gem 'brotli'
end

group :render_template, optional: true do
  gem 'sablon'
end

group :create_document, optional: true do
  gem 'down'
end

group :shared, optional: true do
  gem 'aws-sdk-s3'
  gem 'dynamoid'
  gem 'carrierwave-aws'
end

group :test do
  gem 'pry'
  gem 'rspec'
  gem 'aws-sdk-cloudformation'
  gem 'aws-sdk-lambda'
end
