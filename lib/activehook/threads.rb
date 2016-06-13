module ActiveHook
  class << self
    def thread_pool
      @thread_pool ||= create_thread_pool
    end

    def thread(&_block)
      Concurrent::Future.execute(executor: ActiveHook.thread_pool) { yield }
    end

    def create_thread_pool
      Concurrent::ThreadPoolExecutor.new(
        max_threads: ActiveHook.config.threads_max,
        min_threads: ActiveHook.config.threads_max,
        max_queue: ActiveHook.config.threads_max * 10,
        fallback_policy: :caller_runs
      )
    end
  end
end
