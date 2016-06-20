require 'activehook/workers/manager'

module ActiveHook
  class Server
    def initialize
      at_exit { shutdown }
    end

    def start
      @manager = Workers::Manager.new(ActiveHook.config.worker_options)
      @manager.start
      sleep
    end

    def shutdown
      @manager.shutdown
    end
  end
end
