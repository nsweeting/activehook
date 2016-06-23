module ActiveHook
  module Server
    class Retry
      def initialize
        @done = false
      end

      def start
        until @done
          retries = retrieve_retries
          update(retries) unless retries.empty?
          sleep 2
        end
      end

      def shutdown
        @done = true
      end

      private

      def retrieve_retries
        ActiveHook.redis.with do |conn|
          conn.zrangebyscore('ah:retry', 0, Time.now.to_i)
        end
      end

      def update(retries)
        ActiveHook.redis.with do |conn|
          conn.pipelined do
            conn.zrem('ah:retry', retries)
            conn.incrby('ah:total_retries', retries.count)
          end
        end
        retries.each { |r| RetryRunner.new(r) }
      end
    end

    class RetryRunner
      def initialize(json)
        @json = json
        @hook = Hook.new(JSON.parse(@json))
        start
      end

      def start
        @hook.perform
      end
    end
  end
end
