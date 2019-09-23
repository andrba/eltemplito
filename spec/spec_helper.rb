require "active_support/core_ext/hash/indifferent_access"

app = File.expand_path("../../app", __FILE__)
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(app) unless $LOAD_PATH.include?(app)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

RSpec.configure do |config|
end
