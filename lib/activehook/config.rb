module ActiveHook
  class << self
    def configure
      reset
      yield(config)
    end

    def config
      @config ||= Config.new
    end

    def reset
      @config = nil
      @connection_pool = nil
      @thread_pool = nil
    end
  end

  class Config
    DEFAULTS = { redis_url: ENV['REDIS_URL'],
                 redis_pool: 5,
                 threads_max: 10,
                 retry_max: 3,
                 retry_time: 3600,
                 workers_queued: 3,
                 worker_failed_timer: 300 }

    attr_accessor :redis_url, :redis_pool, :threads_max, :retry_max, :retry_time,
                  :workers_queued, :worker_failed_timer

    def initialize
      DEFAULTS.each { |key, value| send("#{key}=", value) }
    end

    def retry_max_time
      @retry_max_time ||= retry_max * retry_time
    end
  end
end
