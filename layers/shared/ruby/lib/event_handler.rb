class EventHandler
  attr_reader :env

  def initialize(env)
    @env = env
  end

  def handle
    raise NotImplemented
  end

  private

  def params
    env.fetch('params', {})
  end

  def context
    env.fetch('context', {})
  end
end
