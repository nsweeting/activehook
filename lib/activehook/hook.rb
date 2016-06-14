module ActiveHook
  class Hook
    attr_accessor :uri, :payload

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      valid?
      ActiveHook.thread do
        ActiveHook.redis.with do |conn|
          conn.pipelined do
            conn.lpush('ah:queued', to_json)
            conn.incr('ah:total_created')
          end
        end
      end
    end

    def created_at
      @created_at ||= Time.now.to_i
    end

    def created_at=(created_at)
      @created_at = created_at.to_i
    end

    def retry_at
      @retry_at ||= created_at + ActiveHook.config.retry_time
    end

    def retry_at=(retry_at)
      @retry_at = retry_at.to_i
    end

    def fail_at
      @fail_at ||= created_at + ActiveHook.config.retry_max_time
    end

    def fail_at=(fail_at)
      @fail_at = fail_at.to_i
    end

    def to_json
      { created_at: created_at,
        retry_at: retry_at,
        fail_at: fail_at,
        uri: uri.to_s,
        payload: payload }.to_json
    end

    private

    def valid?
      raise Errors::Hook, 'Payload must be a Hash.' unless payload.is_a?(Hash)
      raise Errors::Hook, 'URI is not a valid format.' unless uri =~ /\A#{URI::regexp}\z/
      raise Errors::Hook, 'Created at must be an Integer.' unless created_at.is_a?(Integer)
      raise Errors::Hook, 'Retry at must be an Integer.' unless retry_at.is_a?(Integer)
      raise Errors::Hook, 'Fail at must be an Integer.' unless fail_at.is_a?(Integer)
    end
  end
end
