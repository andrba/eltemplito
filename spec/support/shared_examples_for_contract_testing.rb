require 'pathname'

RSpec.shared_examples "it respects contract with consumer lambda function" do |function_name|
  let(:schema) { Pathname.new(File.join('app', function_name, 'schema.json')) }

  it 'respects the contract' do
    # Convert all symbol keys and values into strings
    stringified_message = JSON.parse(message.to_json)

    expect(JSONSchemer.schema(schema).valid?(stringified_message)).to be_truthy
  end
end
