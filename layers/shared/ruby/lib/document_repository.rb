require 'aws-sdk-dynamodb'

module DocumentRepository
  DB = Aws::DynamoDB::Resource.new

  module_function

  def create(attributes)
    DB.table(ENV['DOCUMENTS_TABLE']).put_item(item: attributes)
  end

  def update(id, attributes)
    DB.table(ENV['DOCUMENTS_TABLE']).update_item(
      key: { id: id },
      update_expression: "set #{attributes.map { |key, value| "#{key} = :#{key}" }.join(",") }",
      expression_attribute_values: attributes.transform_keys { |key| ":#{key}" }
    )
  end
end
