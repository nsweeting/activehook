module ActiveHook
  module Server
    # The Manager controls our Worker processes. We use it to instruct each
    # of them to start and shutdown.
    #
    class Manager
      attr_accessor :workers, :options
      attr_reader :forks

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
        @master = Process.pid
        at_exit { shutdown }
      end

      # Instantiates new Worker objects, setting them with our options. We
      # follow up by booting each of our Workers. Our Manager is then put to
      # sleep so that our Workers can do their thing.
      #
      def start
        validate!
        start_messages
        create_workers
        Process.wait
      end

      # Shutsdown our Worker processes.
      #
      def shutdown
        @forks.each { |w| Process.kill('SIGINT', w[:pid].to_i) }
        Process.kill('SIGINT', @master)
      end

      private

      # Create the specified number of workers and starts them
      #
      def create_workers
        @forks = []
        @workers.times do |id|
          pid = fork { Worker.new(@options.merge(id: id)).start }
          @forks << { id: id, pid: pid }
        end
      end

      # Information about the start process
      #
      def start_messages
        ActiveHook.log.info("* Workers: #{@workers}")
        ActiveHook.log.info("* Threads: #{@options[:queue_threads]} queue, #{@options[:retry_threads]} retry")
      end

      # Validates our data before starting our Workers. Also instantiates our
      # connection pool by pinging Redis.
      #
      def validate!
        raise Errors::Server, 'Cound not connect to Redis.' unless ActiveHook.redis.with { |c| c.ping && c.quit }
        raise Errors::Server, 'Workers must be an Integer.' unless @workers.is_a?(Integer)
        raise Errors::Server, 'Options must be a Hash.' unless @options.is_a?(Hash)
      end
    end
  end
end
