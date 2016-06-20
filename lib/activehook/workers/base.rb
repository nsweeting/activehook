module ActiveHook
  module Workers
    class Base
      def initialize
        @done = false
      end

      def shutdown
        @done = true
      end
    end
  end
end
