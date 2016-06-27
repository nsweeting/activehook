module ActiveHook
  REQUEST_HEADERS = {
    "Content-Type" => "application/json",
    "Accept"       => "application/json",
    "User-Agent"   => "ActiveHook/#{ActiveHook::VERSION}"
  }.freeze

  module Server
    class Send
      attr_accessor :hook
      attr_reader :response_time, :status, :response

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
      end

      def start
        @status = post_hook
        log_status
      end

      def uri
        @uri ||= URI.parse(@hook.uri)
      end

      def success?
        @status == :success
      end

      private

      def post_hook
        http = Net::HTTP.new(uri.host, uri.port)
        measure_response_time do
          @response = http.post(uri.path, @hook.final_payload, final_headers)
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

      def final_headers
        { "X-Hook-Signature" => @hook.signature }.merge(REQUEST_HEADERS)
      end
    end
  end
end
