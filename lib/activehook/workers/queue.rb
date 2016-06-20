require 'activehook/workers/base'
require 'activehook/post'


module ActiveHook
  module Workers
    class Queue < Base
      def start
        until @done
          json = retrieve_hook
          HookRunner.new(json) if json
        end
      end

      private

      def retrieve_hook
        json = ActiveHook.redis.with { |c| c.brpop('ah:queue', @time) }
        json.last if json
      end
    end

    class HookRunner
      def initialize(json)
        @hook = ActiveHook::Hook.new(JSON.parse(json))
        @post = ActiveHook::POST.new(uri: @hook.uri, payload: @hook.payload)
        start
      end

      def start
        @post.start
        ActiveHook.redis.with do |conn|
          @post.success? ? hook_success(conn) : hook_failed(conn)
        end
      end

      private

      def hook_success(conn)
        conn.incr('ah:total_success')
      end

      def hook_failed(conn)
        conn.zadd('ah:retry', @hook.retry_at, @hook.to_json) if @hook.retry?
        conn.incr('ah:total_failed')
      end
    end
  end
end
