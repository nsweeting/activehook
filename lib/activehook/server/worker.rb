module ActiveHook
  module Server
    # The Worker manages our two main processes - Queue and Retry. Each of these
    # processes is alloted a number of threads. These threads are then forked.
    # Each worker object maintains control of these threads through the aptly
    # named start and shutdown methods.
    #
    class Worker
      attr_accessor :queue_threads, :retry_threads, :id

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
        @pid = Process.pid
        @threads = []
        @_threads_real = []
        at_exit { shutdown }
      end

      # Starts our new worker.
      #
      def start
        validate!
        start_message
        build_threads
        start_threads
      end

      # Shutsdown our worker as well as its threads.
      #
      def shutdown
        shutdown_message
        @threads.each(&:shutdown)
        @_threads_real.each(&:exit)
      end

      private

      # Forks the worker and creates the actual threads (@_threads_real) for
      # our Queue and Retry objects. We then start them and join them to the
      # main process.
      #
      def start_threads
        @threads.each do |thread|
          @_threads_real << Thread.new { thread.start }
        end
        @_threads_real.map(&:join)
      end

      # Instantiates our Queue and Retry objects based on the number of threads
      # specified for each process type. We store these objects as an array in
      # @threads.
      #
      def build_threads
        @queue_threads.times { @threads << Queue.new }
        @retry_threads.times { @threads << Retry.new }
      end

      # Information about the start process
      #
      def start_message
        ActiveHook.log.info("* Worker #{@id} started, pid: #{@pid}")
      end

      # Information about the shutdown process
      #
      def shutdown_message
        ActiveHook.log.info("* Worker #{@id} shutdown, pid: #{@pid}")
      end

      # Validates our data before starting the worker.
      #
      def validate!
        raise Errors::Worker, 'Queue threads must be an Integer.' unless @queue_threads.is_a?(Integer)
        raise Errors::Worker, 'Retry threads must be an Integer.' unless @retry_threads.is_a?(Integer)
      end
    end
  end
end
