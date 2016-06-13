module ActiveHook
  module Workers
    class Failed
      def initialize
        perform
      end

      private

      def perform
        ActiveHook.thread do
          loop do
            ActiveHook.redis.with do |redis|
              redis.failed_hooks.each do |json|
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
        ActiveHook.redis.with do |redis|
          redis.remove_hook(@json)
          retry_hook if retry? && !failed?
        end
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
