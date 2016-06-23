module ActiveHook
  module Errors
    class Config < StandardError; end
    class Hook < StandardError; end
    class HTTP < StandardError; end
    class Send < StandardError; end
    class Server < StandardError; end
    class Worker < StandardError; end
  end
end
