app = File.expand_path("../../app", __FILE__)
lib = File.expand_path("../../layers/shared/ruby/lib", __FILE__)
$LOAD_PATH.unshift(app) unless $LOAD_PATH.include?(app)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

RSpec.configure do |config|
end
