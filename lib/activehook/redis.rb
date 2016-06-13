require 'redis'

module ActiveHook
  class << self
    def redis
      connection_pool
    end

    def connection_pool
      @connection_pool ||= create_connection_pool
    end

    def create_connection_pool
      ConnectionPool.new(size: ActiveHook.config.redis_pool) { Redis.new }
    end
  end

  class Redis
    attr_reader :connection

    def initialize
      @connection = ::Redis.new(url: ActiveHook.config.redis_url)
    end

    def await_queued_hook
      @connection.brpoplpush('AH_QUEUE', 'AH_PROC')
    end

    def add_hook(hook)
      @connection.lpush('AH_QUEUE', hook)
    end

    def remove_hook(hook)
      @connection.lrem('AH_PROC', 1, hook)
    end

    def failed_hooks
      @connection.lrange('AH_PROC', 0, 1000)
    end
  end
end
