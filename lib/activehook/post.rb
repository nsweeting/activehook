require 'net/http'
require 'uri'

module ActiveHook
  class POST
    USER_AGENT = "ActiveHook/#{ActiveHook::VERSION}".freeze

    attr_accessor :uri, :payload
    attr_reader :response_time

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def perform
      http_post
      status_message
      status
    end

    def status
      @status ||= set_status
    end

    private

    def http_post
      new_uri = URI.parse(uri)
      http = Net::HTTP.new(new_uri.host, new_uri.port)
      measure_response_time do
        @response = http.post(new_uri.path, payload.to_json, {"Content-Type" => "application/json", "Accept" => "application/json"})
        #@response = Curl::Easy.http_post(uri, payload.to_json) do |curl|
          #curl.headers['Accept'] = 'application/json'
          #curl.headers['Content-Type'] = 'application/json'
          #curl.headers['User-Agent'] = USER_AGENT
        #end
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
      case @response.code.to_i
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
  end
end
