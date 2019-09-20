require 'json_schemer'

class ValidateSchema
  class SchemaError < StandardError; end

  def initialize(app, schema)
    @app = app
    @schemer = schema && JSONSchemer.schema(schema)
  end

  def call(env)
    if @schemer && !@schemer.valid?(env['params'])
      raise SchemaError, schemer.validate(env['params'])
    end

    @app.call(env)
  end
end
