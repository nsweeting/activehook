module ActiveHook
  module Server
    # The Queue object processes any hooks that are queued into our Redis server.
    # It will perform a 'blocking pop' on our hook list until one is added.
    #
    class Queue
      def initialize
        @done = false
      end

      # Starts our queue process. This will run until instructed to stop.
      #
      def start
        until @done
          json = retrieve_hook
          HookRunner.new(json) if json
        end
      end

      # Shutsdown our queue process.
      #
      def shutdown
        @done = true
      end

      private

      # Performs a 'blocking pop' on our redis queue list.
      #
      def retrieve_hook
        json = ActiveHook.redis.with { |c| c.brpop('ah:queue') }
        json.last if json
      end
    end

    class HookRunner
      def initialize(json)
        @hook = Hook.new(JSON.parse(json))
        @post = Send.new(uri: @hook.uri, payload: @hook.secure_payload)
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
