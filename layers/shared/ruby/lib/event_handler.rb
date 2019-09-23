require "active_support/core_ext/hash/indifferent_access"

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
    env.fetch(:params, {})
  end
end
