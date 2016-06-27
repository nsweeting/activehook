module ActiveHook
  class << self
    def configure
      reset
      yield(config)
    end

    def config
      @config ||= build_config
    end

    def build_config
      klass =
        case ActiveHook.mode
        when :server then ActiveHook::Server::Config
        when :client then ActiveHook::Client::Config
        else ActiveHook::App::Config
        end
      klass.new
    end

    def reset
      @config = nil
      @connection_pool = nil
    end
  end

  class BaseConfig
    BASE_DEFAULTS = {
      redis_url: ENV['REDIS_URL'],
      redis_pool: 5,
      signature_header: 'X-Webhook-Signature'
    }.freeze

    attr_accessor :redis_url, :redis_pool, :signature_header

    def initialize
      BASE_DEFAULTS.each { |key, value| send("#{key}=", value) }
    end

    def redis
      {
        size: redis_pool,
        url: redis_url
      }
    end
  end
end
