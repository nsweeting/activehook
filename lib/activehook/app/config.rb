module ActiveHook
  module App
    class Config < ActiveHook::BaseConfig
      OTHER_DEFAULTS = {
        validation_path: '/hooks/validate',
        creation_path: '/hooks'
      }.freeze

      attr_accessor :validation_path, :creation_path

      def initialize
        super
        OTHER_DEFAULTS.each { |key, value| send("#{key}=", value) }
      end
    end
  end
end
