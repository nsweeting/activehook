module ActiveHook
  module Workers
    class Runner
      def initialize(json: nil)
        @json = json
        @hook = Hook.new(JSON.parse(@json))
        perform
      end
    end
  end
end
