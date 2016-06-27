module ActiveHook
  class Hook
    attr_accessor :token, :uri, :payload, :id, :key, :retry_max, :retry_time, :created_at

    def initialize(options = {})
      options = defaults.merge(options)
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      validate!
      ActiveHook.redis.with do |conn|
        @id = conn.incr('ah:total_queued')
        conn.lpush('ah:queue', to_json)
        conn.zadd('ah:validation', @id, @key)
      end
    end

    def retry?
      fail_at > Time.now.to_i
    end

    def retry_at
      Time.now.to_i + @retry_time.to_i
    end

    def fail_at
      @created_at.to_i + retry_max_time
    end

    def retry_max_time
      @retry_time.to_i * @retry_max.to_i
    end

    def to_json
      { id: @id,
        key: @key,
        token: @token,
        created_at: @created_at,
        retry_time: @retry_time,
        retry_max: @retry_max,
        uri: @uri,
        payload: @payload }.to_json
    end

    def final_payload
      { hook_id: @id,
        hook_key: @key,
        hook_time: @created_at,
        hook_signature: ActiveHook.config.signature_header,
        payload: @payload }.to_json
    end

    def signature
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @token, final_payload)
    end

    private

    def defaults
      { key: SecureRandom.uuid,
        created_at: Time.now.to_i,
        retry_time: 3600,
        retry_max: 3 }
    end

    def validate!
      raise Errors::Hook, 'Token must be a String.' unless @token.is_a?(String)
      raise Errors::Hook, 'Payload must be a Hash.' unless @payload.is_a?(Hash)
      raise Errors::Hook, 'URI is not a valid format.' unless @uri =~ /\A#{URI::regexp}\z/
      raise Errors::Hook, 'Created at must be an Integer.' unless @created_at.is_a?(Integer)
      raise Errors::Hook, 'Retry time must be an Integer.' unless @retry_time.is_a?(Integer)
      raise Errors::Hook, 'Retry max must be an Integer.' unless @retry_max.is_a?(Integer)
    end
  end
end
