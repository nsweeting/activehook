require 'redis'

module ActiveHook
  class << self
    attr_reader :connection_pool

    def redis
      @connection_pool ||= ConnectionPool.create
    end
  end

  class ConnectionPool
    def self.create
      ::ConnectionPool.new(size: ActiveHook.config.redis_pool) do
        Redis.new(url: ActiveHook.config.redis_url)
      end
    end
  end
end
