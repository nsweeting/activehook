require 'curb'

module ActiveHook
  class POST
    USER_AGENT = "ActiveHook/#{ActiveHook::VERSION}"

    attr_accessor :uri, :payload
    attr_reader :response_time

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      valid?
      http_post
      status_message
      status
    end

    def status
      @status ||= set_status
    end

    private

    def http_post
      measure_response_time do
        @response = Curl::Easy.http_post(uri, payload.to_json) do |curl|
          curl.headers['Accept'] = 'application/json'
          curl.headers['Content-Type'] = 'application/json'
          curl.headers['User-Agent'] = USER_AGENT
        end
      end
    rescue
      @status = :error
    end

    def measure_response_time
      start = Time.now
      yield
      finish = Time.now
      @response_time = "#{((finish - start) * 1000.0).round(3)} ms"
    end

    def set_status
      case @response.status.to_i
      when (200..204)
        :success
      when (400..499)
        :bad_request
      when (500..599)
        :server_problems
      end
    end

    def status_message
      msg = "POST | #{uri} | #{status.upcase} | #{response_time}"
      if status == :success
        ActiveHook.log.info(msg)
      else
        ActiveHook.log.err(msg)
      end
    end

    def valid?
      raise Errors::HTTP, 'Payload must be a Hash.' unless payload.is_a?(Hash)
      raise Errors::HTTP, 'URI is not a valid format.' unless uri =~ /\A#{URI::regexp}\z/
    end
  end
end
