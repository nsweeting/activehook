module ActiveHook
  module Server
    class Retry
      def initialize
        @done = false
      end

      def start
        until @done
          ActiveHook.redis.with do |conn|
            conn.watch('ah:retry') do
              retries = retrieve_retries(conn)
              update_retries(conn, retries)
            end
          end
          sleep 2
        end
      end

      def shutdown
        @done = true
      end

      private

      def retrieve_retries(conn)
        conn.zrangebyscore('ah:retry', 0, Time.now.to_i)
      end

      def update_retries(conn, retries)
        if retries.any?
          conn.multi do |multi|
            multi.incrby('ah:total_retries', retries.count)
            multi.zrem('ah:retry', retries)
            multi.lpush('ah:queue', retries)
          end
        else
          conn.unwatch
        end
      end
    end
  end
end
