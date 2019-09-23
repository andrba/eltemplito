class ParseEvent
  class UnknownEventParser
    SOURCE = 'unknown'

    attr_reader :env

    def initialize(env)
      @env = env
    end

    def parsable?
      true
    end

    def parse
      {
        params: env[:event],
        source: SOURCE
      }
    end
  end
end
