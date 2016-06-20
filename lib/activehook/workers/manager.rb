require 'activehook/workers/queue'
require 'activehook/workers/retry'

module ActiveHook
  module Workers
    class Manager
      attr_accessor :worker_count, :queue_threads, :retry_threads

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
        @workers = []
        @forks = []
        build_workers
      end

      def start
        @workers.each do |worker|
          ActiveHook.log.info("New worker starting - #{worker.class.name}")
          @forks << fork { worker.start }
        end
      end

      def shutdown
        @workers.each(&:shutdown)
      end

      private

      def build_workers
        @worker_count.times do
          @workers << Worker.new(queue_threads: queue_threads,
                                 retry_threads: retry_threads)
        end
      end
    end

    class Worker
      attr_accessor :queue_threads, :retry_threads
      attr_reader :workers, :threads

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
        @threads = []
        @_threads_real = []
        build_threads
      end

      def start
        @threads.each { |thread| @_threads_real << Thread.new { thread.start } }
        @_threads_real.map(&:join)
      end

      def shutdown
        @threads.each(&:shutdown)
        @_threads_real.each(&:exit)
      end

      private

      def build_threads
        @queue_threads.times { @threads << Queue.new }
        @retry_threads.times { @threads << Retry.new }
      end
    end
  end
end
