require 'json-schema'

class ValidateSchema
  def initialize(app, schema)
    @app = app
    @schema = schema
  end

  def call(env)
    JSON::Validator.validate!(@schema, env['event'])
    @app.call(env)
  end
end
