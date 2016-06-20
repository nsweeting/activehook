require 'securerandom'

module ActiveHook
  class Hook
    attr_accessor :uri, :payload, :id, :created_at, :retry_at, :fail_at

    def initialize(options = {})
      options = defaults.merge(options)
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      valid?
      ActiveHook.redis.with do |conn|
        conn.pipelined do
          conn.lpush('ah:queue', to_json)
          conn.incr('ah:total_queued')
        end
      end
    end

    def bump_retry
      @retry_at = Time.now.to_i + ActiveHook.config.retry_time
    end

    def retry?
      @fail_at.to_i > Time.now.to_i
    end

    def to_json
      { id: @id,
        created_at: @created_at,
        retry_at: @retry_at,
        fail_at: @fail_at,
        uri: @uri,
        payload: @payload }.to_json
    end

    private

    def defaults
      { id: SecureRandom.uuid,
        created_at: Time.now.to_i,
        retry_at: Time.now.to_i + ActiveHook.config.retry_time,
        fail_at: Time.now.to_i + ActiveHook.config.retry_max_time }
    end

    def valid?
      raise Errors::Hook, 'Payload must be a Hash.' unless @payload.is_a?(Hash)
      raise Errors::Hook, 'URI is not a valid format.' unless @uri =~ /\A#{URI::regexp}\z/
      raise Errors::Hook, 'Created at must be an Integer.' unless @created_at.is_a?(Integer)
      raise Errors::Hook, 'Retry at must be an Integer.' unless @retry_at.is_a?(Integer)
      raise Errors::Hook, 'Fail at must be an Integer.' unless @fail_at.is_a?(Integer)
    end
  end
end
