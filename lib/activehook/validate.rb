module ActiveHook
  class Validate
    attr_accessor :id, :key

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      validate!
      @key == find_key
    rescue
      false
    end

    private

    def find_key
      ActiveHook.redis.with do |conn|
        conn.zrangebyscore('ah:validation', @id.to_i, @id.to_i).first
      end
    end

    def validate!
      raise Errors::Validation, 'ID must be an integer.' unless @id.is_a?(Integer)
      raise Errors::Validation, 'Key must be a a string.' unless @key.is_a?(String) && @key.length > 6
    end
  end
end
