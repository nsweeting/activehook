module ActiveHook
  module Client
    class Config < ActiveHook::BaseConfig
      OTHER_DEFAULTS = {
        validation_uri: '',
        validation_token: ''
      }.freeze

      attr_accessor :validation_uri, :validation_token

      def initialize
        super
        OTHER_DEFAULTS.each { |key, value| send("#{key}=", value) }
      end
    end
  end
end
