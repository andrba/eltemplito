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
    env['params']
  end
end
