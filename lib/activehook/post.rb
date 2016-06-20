require 'net/http'
require 'uri'

module ActiveHook
  class POST
    HEADERS = {
      "Content-Type" => "application/json",
      "Accept"       => "application/json",
      "User-Agent"   => "ActiveHook/#{ActiveHook::VERSION}"
    }.freeze

    attr_accessor :payload
    attr_reader :response_time, :uri, :status, :response

    def initialize(options = {})
      options.each { |key, value| send("#{key}=", value) }
    end

    def start
      @status = post_hook
      log_status
    end

    def uri=(uri)
      @uri = URI.parse(uri)
    end

    def success?
      status == :success
    end

    private

    def post_hook
      http = Net::HTTP.new(uri.host, uri.port)
      measure_response_time do
        @response = http.post(uri.path, payload.to_json, HEADERS)
      end
      response_status(@response)
    rescue
      :error
    end

    def measure_response_time
      start = Time.now
      yield
      finish = Time.now
      @response_time = "| #{((finish - start) * 1000.0).round(3)} ms"
    end

    def response_status(response)
      case response.code.to_i
      when (200..204)
        :success
      when (400..499)
        :bad_request
      when (500..599)
        :server_problems
      end
    end

    def log_status
      msg = "POST | #{uri} | #{status.upcase} #{response_time}"
      if status == :success
        ActiveHook.log.info(msg)
      else
        ActiveHook.log.err(msg)
      end
    end
  end
end
