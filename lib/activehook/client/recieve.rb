module ActiveHook
  module Client
    module Recieve

      REQUEST_HEADERS = {
        "Content-Type" => "application/json",
        "Accept"       => "application/json",
        "User-Agent"   => "ActiveHook/#{ActiveHook::VERSION}"
      }.freeze

      attr_accessor :request, :token

      def initialize(options = {})
        options.each { |key, value| send("#{key}=", value) }
      end

      def signature_valid?
        @signature_valid ||= validate_signature
      end

      def server_valid?
        @server_valid ||= validate_server
      end

      def payload
        parsed_body['payload']
      rescue
        nil
      end

      def validated_payload
        raise StandardError, 'Webhook is invalid.' unless hook_valid?
        @payload
      end

      private

      def parsed_body
        @parsed_body ||= JSON.parse(request.body.read)
      rescue
        {}
      end

      def hook_id
        parsed_body['hook_id']
      end

      def hook_key
        parsed_body['hook_key']
      end

      def hook_uri
        @hook_uri ||= URI.parse(self.class::VALIDATION_URI)
      end

      def hook_signature
        @request.env["HTTP_#{parsed_body['hook_signature']}"]
      end

      def validate_server
        http = Net::HTTP.new(hook_uri.host, hook_uri.port)
        response = http.post(hook_uri.path, hook_json, REQUEST_HEADERS)
        response.code.to_i == 200 ? true : false
      rescue
        false
      end

      def validate_signature
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @token, payload)
        Rack::Utils.secure_compare(signature, hook_signature)
      rescue
        false
      end

      def hook_json
        { id: hook_id,
          key: hook_key }.to_json
      end
    end
  end

  class Recieve
    include ActiveHook::Client::Recieve

    VALIDATION_URI = (ActiveHook.config.validation_uri).freeze
  end
end
