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

group :listen_document_stream, optional: true do
  gem 'aws-sdk-sns'
end

group :shared, optional: true do
  gem 'aws-sdk-s3'
  gem 'aws-sdk-dynamodb'
  gem 'aws-sdk-lambda'
end

group :test, :development do
  gem 'pry'
  gem 'rspec'
  gem 'aws-sdk-cloudformation'
end
