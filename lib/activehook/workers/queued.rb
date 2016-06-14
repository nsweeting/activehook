require 'activehook/post'

module ActiveHook
  module Workers
    class Queued
      def initialize
        ActiveHook.log.info('Queued hooks worker booted')
        perform
      end

      private

      def perform
        ActiveHook.thread do
          loop do
            json = ActiveHook.redis.with do |conn|
              conn.brpoplpush('ah:queued', 'ah:failed')
            end
            ActiveHook.thread { QueuedRunner.new(json: json) }
          end
        end
      end
    end

    class QueuedRunner < Runner
      private

      def perform
        post = ActiveHook::POST.new(uri: @hook.uri, payload: @hook.payload)
        ActiveHook.redis.with do |conn|
          conn.pipelined do
            conn.incr('ah:total_processed')
            break unless post.perform == :success
            conn.lrem('ah:failed', 1, @json)
            conn.incr('ah:total_success')
          end
        end
      end
    end
  end
end
