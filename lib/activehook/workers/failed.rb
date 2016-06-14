module ActiveHook
  module Workers
    class Failed
      def self.run
        Workers::Failed.new
      end

      def initialize
        ActiveHook.log.info('Failed hooks worker booted')
        perform
      end

      private

      def perform
        Concurrent::Future.execute do
          loop do
            ActiveHook.redis.with do |conn|
              conn.lrange('ah:failed', 0, 1000).each do |json|
                ActiveHook.thread { FailedRunner.new(json: json) }
              end
            end
            sleep ActiveHook.config.worker_failed_timer
          end
        end
      end
    end

    class FailedRunner < Runner
      private

      def perform
        return unless failed? || retry?
        ActiveHook.redis.with do |conn|
          conn.pipelined do
            conn.lrem('ah:failed', 1, @json)
            conn.incr('ah:total_failed') if failed?
          end
        end
        retry_hook if retry? && !failed?
      end

      def retry_hook
        @hook.retry_at = time + ActiveHook.config.retry_time
        @hook.perform
      end

      def failed?
        @failed ||= time > @hook.fail_at
      end

      def retry?
        @retry ||= time > @hook.retry_at
      end

      def time
        @time ||= Time.now.to_i
      end
    end
  end
end
