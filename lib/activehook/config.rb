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
    attr_writer :redis_url, :redis_pool, :threads_max, :retry_max, :retry_time,
                :workers_queued, :worker_failed_timer

    def redis_url
      @redis_url ||= ENV['REDIS_URL']
    end

    def redis_pool
      @redis_pool ||= 5
    end

    def threads_max
      @threads_max ||= 5
    end

    def retry_max
      @retry_max ||= 3
    end

    def retry_time
      @retry_time ||= 3600
    end

    def retry_max_time
      @retry_max_time ||= retry_max * retry_time
    end

    def workers_queued
      @workers_queued ||= 3
    end

    def worker_failed_timer
      @worker_failed_timer ||= 60
    end
  end
end
