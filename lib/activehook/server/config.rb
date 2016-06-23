module ActiveHook
  module Server
    class Config < ActiveHook::BaseConfig
      OTHER_DEFAULTS = {
        workers: 2,
        queue_threads: 2,
        retry_threads: 1
      }.freeze

      attr_accessor :workers, :queue_threads, :retry_threads

      def initialize
        super
        OTHER_DEFAULTS.each { |key, value| send("#{key}=", value) }
      end

      def worker_options
        {
          queue_threads: queue_threads,
          retry_threads: retry_threads
        }
      end

      def manager_options
        {
          workers: workers,
          options: worker_options
        }
      end
    end
  end
end
