require 'json_schemer'
require 'pathname'

class ValidateSchema
  class SchemaError < StandardError; end

  def initialize(app, schema)
    @app = app
    @schemer = schema && JSONSchemer.schema(Pathname.new(schema))
  end

  def call(env)
    if @schemer && !@schemer.valid?(env[:params])
      raise SchemaError, @schemer.validate(env[:params]).to_a
    end

    @app.call(env)
  end
end
