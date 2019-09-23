class PartialFailureHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless env[:params].is_a?(Array)

    failures = []

    env[:params].each do |record|
      begin
        @app.call(env.dup.merge(params: record))
      rescue => exception
        failures << {
          record:  record,
          message: exception.message,
          backtrace: exception.backtrace
        }
      end
    end

    failures.each do |(event_id, failure)|
      # TODO: Attempt to invoke the same lambda function asyncronously, e.g.
      # Lambda.invoke_async(function_name: env[...], invoke_args: failure[:record])
      puts failure
    end
  end
end
