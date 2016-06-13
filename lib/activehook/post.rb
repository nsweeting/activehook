require 'curb'

module ActiveHook
  class POST
    USER_AGENT = "ActiveHook/#{ActiveHook::VERSION}"

    attr_accessor :uri, :payload, :status

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      valid?
      @status = post_hook
    end

    private

    def post_hook
      response = Curl::Easy.http_post(uri, payload.to_json) do |curl|
        curl.headers['Accept'] = 'application/json'
        curl.headers['Content-Type'] = 'application/json'
        curl.headers['User-Agent'] = USER_AGENT
      end
      response_status(response.status.to_i)
    rescue
      :error
    end

    def response_status(code)
      case code
      when (200..201)
        :success
      when (400..499)
        :bad_request
      when (500..599)
        :server_problems
      end
    end

    def valid?
      raise Errors::HTTP, 'Payload must be a Hash.' unless payload.is_a?(Hash)
      raise Errors::HTTP, 'URI is not a valid format.' unless uri =~ /\A#{URI::regexp}\z/
    end
  end
end
