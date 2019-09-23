class ParseEvent
  class SnsEventParser
    SOURCE = 'sns'

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def parsable?
      records && records.first[:EventSource].to_s.start_with?('aws:sns')
    end

    def parse
      {
        params: JSON.parse(records.first.dig(:Sns, :Message)),
        source: SOURCE
      }
    end

    def records
      env.dig(:event, :Records)
    end
  end
end
