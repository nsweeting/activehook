module ActiveHook
  module Client
    class Config < ActiveHook::BaseConfig
      OTHER_DEFAULTS = {
        validation_uri: 'http://localhost:3000/hooks/validate'
      }.freeze

      attr_accessor :validation_uri

      def initialize
        super
        OTHER_DEFAULTS.each { |key, value| send("#{key}=", value) }
      end
    end
  end
end
