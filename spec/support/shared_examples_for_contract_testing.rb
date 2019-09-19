RSpec.shared_examples "it respects contract with consumer lambda function" do |function_name|
  let(:schema) { JSON.parse(File.read(File.join('app', function_name, 'schema.json'))) }

  it 'respects the contract' do
    expect(JSON::Validator.validate(schema, message)).to be_truthy
  end
end
