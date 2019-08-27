require 'aws-sdk-cloudformation'

app = File.expand_path("../../app", __FILE__)
$LOAD_PATH.unshift(app) unless $LOAD_PATH.include?(app)

RSpec.configure do |config|
end
