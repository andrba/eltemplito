require 'pathname'
require 'active_support/core_ext/object/json'

RSpec.shared_examples "it respects contract with consumer lambda function" do |function_name|
  let(:schema) { Pathname.new(File.join('app', function_name, 'schema.json')) }

  it 'respects the contract' do
    expect(JSONSchemer.schema(schema).valid?(message.as_json)).to be_truthy
  end
end
