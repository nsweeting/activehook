module ActiveHook
  class << self
    def thread_pool
      @thread_pool ||= ThreadPool.create
    end

    def thread
      Concurrent::Future.execute(executor: ActiveHook.thread_pool) { yield }
    end

    class ThreadPool
      def self.create
        Concurrent::ThreadPoolExecutor.new(
          max_threads: ActiveHook.config.threads_max,
          min_threads: ActiveHook.config.threads_max,
          max_queue: ActiveHook.config.threads_max * 5,
          fallback_policy: :caller_runs)
      end
    end
  end
end
