require 'activehook/post'

module ActiveHook
  module Workers
    class Queued
      def initialize
        perform
      end

      private

      def perform
        ActiveHook.thread do
          loop do
            json = ActiveHook.redis.with(&:await_queued_hook)
            ActiveHook.thread { QueuedRunner.new(json: json) }
          end
        end
      end
    end

    class QueuedRunner < Runner
      private

      def perform
        post = ActiveHook::POST.new(uri: @hook.uri, payload: @hook.payload)
        status = post.perform
        ActiveHook.redis.with { |r| r.remove_hook(@json) } if status == :success
      end
    end
  end
end
