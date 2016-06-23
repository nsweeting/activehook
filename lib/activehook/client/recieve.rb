module ActiveHook
  module Client
    module Recieve

      REQUEST_HEADERS = {
        "Content-Type" => "application/json",
        "Accept"       => "application/json",
        "User-Agent"   => "ActiveHook/#{ActiveHook::VERSION}"
      }.freeze

      attr_accessor :hook_id, :hook_key
      attr_reader :payload

      def hook_valid?
        @hook_valid ||= validate_hook
      end

      def payload=(payload)
        @payload = JSON.parse(payload)
      rescue
        nil
      end

      def validated_payload
        raise StandardError, 'Webhook is invalid.' unless hook_valid?
        @payload
      end

      private

      def hook_uri
        @hook_uri ||= URI.parse(self.class::VALIDATION_URI)
      end

      def validate_hook
        http = Net::HTTP.new(hook_uri.host, hook_uri.port)
        response = http.post(hook_uri.path, hook_json, REQUEST_HEADERS)
        response.code.to_i == 200 ? true : false
      rescue
        false
      end

      def hook_json
        { id: @hook_id,
          key: @hook_key }.to_json
      end
    end
  end

  class Recieve
    include ActiveHook::Client::Recieve

    VALIDATION_URI = (ActiveHook.config.validation_uri).freeze
  end
end
