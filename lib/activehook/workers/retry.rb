require 'activehook/workers/base'

module ActiveHook
  module Workers
    class Retry < Base
      def start
        until @done
          retries = retrieve_retries
          update(retries) unless retries.empty?
          sleep 2
        end
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
        @hook = ActiveHook::Hook.new(JSON.parse(@json))
        start
      end

      def start
        @hook.bump_retry
        @hook.perform
      end
    end
  end
end
