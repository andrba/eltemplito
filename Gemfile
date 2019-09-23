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

group :dispatchr, optional: :true do
  gem 'aws-sdk-lambda'
end

group :shared, optional: true do
  gem 'activesupport', require: false
  gem 'aws-sdk-s3'
  gem 'aws-sdk-dynamodb'
  gem 'aws-sdk-sns'
  gem 'json_schemer'
  gem 'ibsciss-middleware'
end

group :test, :development do
  gem 'pry'
  gem 'rspec'
  gem 'aws-sdk-cloudformation'
end
