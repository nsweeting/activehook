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
    end
  end

  class Config
    DEFAULTS = {
      redis_url: ENV['REDIS_URL'],
      redis_pool: 5,
      workers: 2,
      queue_threads: 4,
      retry_threads: 2,
      retry_max: 3,
      retry_time: 3600,
    }.freeze

    attr_accessor :redis_url, :redis_pool, :retry_max, :retry_time,
                  :workers, :queue_threads, :retry_threads

    def initialize
      DEFAULTS.each { |key, value| send("#{key}=", value) }
    end

    def retry_max_time
      @retry_max_time ||= retry_max * retry_time
    end

    def worker_options
      {
        worker_count: workers,
        queue_threads: queue_threads,
        retry_threads: retry_threads
      }
    end
  end
end
