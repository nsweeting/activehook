require 'activehook/post'

module ActiveHook
  module Workers
    class Queued
      def self.run
        (1..ActiveHook.config.workers_queued).each do
          Workers::Queued.new
        end
      end

      def initialize
        ActiveHook.log.info('Queued hooks worker booted')
        perform
      end

      private

      def perform
        Concurrent::Future.execute do
          loop do
            json = ActiveHook.redis.with do |conn|
              conn.brpoplpush('ah:queued', 'ah:failed')
            end
            ActiveHook.thread { QueuedRunner.new(json: json) }
            sleep 0.1
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
            break unless post.perform == :success
            conn.lrem('ah:failed', 1, @json)
            conn.incr('ah:total_success')
          end
        end
      end
    end
  end
end
